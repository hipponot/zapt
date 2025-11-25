# CloudFormation-based cluster definition loader for zapt
# This module provides functions to load cluster definitions from CloudFormation
# stack outputs and EC2 instance tags instead of YAML files.
#
# Usage:
#   Set CLUSTER_DEF_SOURCE=cloudformation to use CF-based loading
#   Or call Zapt::ClusterDefCF.load_from_stack(stack_name) directly
#
# Features:
#   - Caches AWS API responses for 60 seconds to reduce API calls
#   - Parallelizes independent AWS API calls for faster loading
#   - Loads production RTP hosts from SSM Parameter Store (with fallback)
#
require 'json'

module Zapt
  module ClusterDefCF
    # Cache for AWS API responses to reduce API calls during multi-task deployments
    @cache = {}
    @cache_ttl = 60 # seconds

    # Default production RTP channel hosts (fallback if SSM param not found)
    DEFAULT_PROD_RTP_CHANNEL_HOSTS = {
      A: [
        'https://comms0.wootmath.com',
        'https://comms1.wootmath.com',
        'https://comms2.wootmath.com'
      ],
      B: [
        'https://comms3.wootmath.com',
        'https://comms4.wootmath.com',
        'https://comms5.wootmath.com'
      ]
    }.freeze

    class << self
      # Clear the cache (useful for testing or forced refresh)
      def clear_cache!
        @cache = {}
      end

      # Get cached value or fetch and cache
      def cached_fetch(cache_key, &block)
        @cache ||= {}
        if @cache[cache_key] && (Time.now - @cache[cache_key][:time]) < (@cache_ttl || 60)
          return @cache[cache_key][:data]
        end
        data = block.call
        @cache[cache_key] = { data: data, time: Time.now }
        data
      end

      # Check if we should use CloudFormation-based loading
      def use_cloudformation?
        ENV['CLUSTER_DEF_SOURCE'] == 'cloudformation'
      end

      # Get the current instance's metadata using IMDSv2
      def get_instance_metadata(path)
        cached_fetch("metadata:#{path}") do
          # Get token for IMDSv2
          token = `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null`.strip
          next nil if token.empty?

          # Use token to get metadata
          result = `curl -s -H "X-aws-ec2-metadata-token: #{token}" "http://169.254.169.254/latest/meta-data/#{path}" 2>/dev/null`.strip
          result.empty? ? nil : result
        end
      end

      # Get the current instance ID from EC2 metadata
      def get_current_instance_id
        get_instance_metadata('instance-id')
      end

      # Get the current region from EC2 metadata
      def get_current_region
        az = get_instance_metadata('placement/availability-zone')
        az ? az.chop : nil  # Remove last char (zone letter) to get region
      end

      # Get instance tags using AWS CLI
      def get_instance_tags(instance_id, region = nil)
        region ||= get_current_region
        cached_fetch("tags:#{instance_id}:#{region}") do
          cmd = "aws ec2 describe-tags --filters \"Name=resource-id,Values=#{instance_id}\" --region #{region} --output json 2>/dev/null"
          result = `#{cmd}`
          next {} if result.empty?

          tags = {}
          JSON.parse(result)['Tags'].each do |tag|
            tags[tag['Key']] = tag['Value']
          end
          tags
        end
      rescue JSON::ParserError
        {}
      end

      # Get CloudFormation stack outputs
      def get_stack_outputs(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cached_fetch("outputs:#{stack_name}:#{region}") do
          cmd = "aws cloudformation describe-stacks --stack-name #{stack_name} --region #{region} --output json 2>/dev/null"
          result = `#{cmd}`
          next {} if result.empty?

          outputs = {}
          stack = JSON.parse(result)['Stacks']&.first
          next {} unless stack

          (stack['Outputs'] || []).each do |output|
            outputs[output['OutputKey']] = output['OutputValue']
          end
          outputs
        end
      rescue JSON::ParserError
        {}
      end

      # Get CloudFormation stack parameters
      def get_stack_parameters(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cached_fetch("params:#{stack_name}:#{region}") do
          cmd = "aws cloudformation describe-stacks --stack-name #{stack_name} --region #{region} --output json 2>/dev/null"
          result = `#{cmd}`
          next {} if result.empty?

          params = {}
          stack = JSON.parse(result)['Stacks']&.first
          next {} unless stack

          (stack['Parameters'] || []).each do |param|
            params[param['ParameterKey']] = param['ParameterValue']
          end
          params
        end
      rescue JSON::ParserError
        {}
      end

      # Get SSM parameter value
      def get_ssm_parameter(param_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cached_fetch("ssm:#{param_name}:#{region}") do
          cmd = "aws ssm get-parameter --name #{param_name} --region #{region} --output json 2>/dev/null"
          result = `#{cmd}`
          next nil if result.empty?

          JSON.parse(result).dig('Parameter', 'Value')
        end
      rescue JSON::ParserError
        nil
      end

      # Get production RTP channel hosts from SSM or use default
      def get_prod_rtp_channel_hosts(region = nil)
        # Try to load from SSM Parameter Store
        ssm_value = get_ssm_parameter('/prod/rtp/channel-hosts', region)
        if ssm_value
          begin
            parsed = JSON.parse(ssm_value)
            return {
              A: Array(parsed['A']),
              B: Array(parsed['B'])
            }
          rescue JSON::ParserError
            # Fall through to default
          end
        end

        # Return default if SSM not configured
        DEFAULT_PROD_RTP_CHANNEL_HOSTS
      end

      # Try to find associated routing stack for an instance stack
      # Convention: instance stack "foo-box" -> routing stack "foo-box-routing" or "foo-routing"
      def find_routing_stack(instance_stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'

        # Try common naming patterns
        candidates = [
          "#{instance_stack_name}-routing",           # snapper-box -> snapper-box-routing
          instance_stack_name.sub(/-box$/, '-routing') # snapper-box -> snapper-routing
        ].uniq

        candidates.each do |candidate|
          outputs = get_stack_outputs(candidate, region)
          return candidate if outputs.any?
        end

        nil
      end

      # Get routing info from routing stack (frontend_host, rtp_channel_hosts)
      def get_routing_info(routing_stack_name, region = nil)
        return {} unless routing_stack_name

        outputs = get_stack_outputs(routing_stack_name, region)
        params = get_stack_parameters(routing_stack_name, region)

        info = {}

        # DNSName output is the frontend_host
        if outputs['DNSName']
          info[:frontend_host] = "https://#{outputs['DNSName']}"
        end

        # Build rtp_channel_hosts for dev VMs:
        # - Channel A: shared dev comms server (comms-dev1.wootmath.com)
        # - Channel B: VM-specific comms if CreateComms=true, otherwise same as A
        shared_comms = "https://comms-dev1.wootmath.com/"

        if params['CreateComms'] == 'true' && params['Identifier'] && params['PrivateHostedZoneName']
          vm_comms = "https://comm-#{params['Identifier']}.#{params['PrivateHostedZoneName']}"
          info[:rtp_channel_hosts] = { A: [shared_comms], B: [vm_comms] }
        else
          # No VM-specific comms, use shared for both channels
          info[:rtp_channel_hosts] = { A: [shared_comms], B: [shared_comms] }
        end

        info
      end

      # Get all EC2 instances in a CloudFormation stack
      def get_stack_instances(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cached_fetch("instances:#{stack_name}:#{region}") do
          cmd = "aws ec2 describe-instances --filters \"Name=tag:aws:cloudformation:stack-name,Values=#{stack_name}\" \"Name=instance-state-name,Values=running\" --region #{region} --output json 2>/dev/null"
          result = `#{cmd}`
          next [] if result.empty?

          instances = []
          JSON.parse(result)['Reservations'].each do |reservation|
            reservation['Instances'].each do |instance|
              instances << instance
            end
          end
          instances
        end
      rescue JSON::ParserError
        []
      end

      # Get all EC2 instances in an AutoScaling Group
      def get_asg_instances(asg_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cached_fetch("asg:#{asg_name}:#{region}") do
          # First get instance IDs from the ASG
          asg_cmd = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names #{asg_name} --region #{region} --output json 2>/dev/null"
          asg_result = `#{asg_cmd}`
          next [] if asg_result.empty?

          asg_data = JSON.parse(asg_result)
          asg = asg_data['AutoScalingGroups']&.first
          next [] unless asg

          instance_ids = asg['Instances']&.select { |i| i['LifecycleState'] == 'InService' }&.map { |i| i['InstanceId'] }
          next [] if instance_ids.nil? || instance_ids.empty?

          # Then get full instance details
          ids_str = instance_ids.join(' ')
          ec2_cmd = "aws ec2 describe-instances --instance-ids #{ids_str} --region #{region} --output json 2>/dev/null"
          ec2_result = `#{ec2_cmd}`
          next [] if ec2_result.empty?

          instances = []
          JSON.parse(ec2_result)['Reservations'].each do |reservation|
            reservation['Instances'].each do |instance|
              instances << instance if instance['State']['Name'] == 'running'
            end
          end
          instances
        end
      rescue JSON::ParserError
        []
      end

      # Build node configuration from EC2 instance data
      def build_node_from_instance(instance, default_user = 'ubuntu')
        tags = {}
        (instance['Tags'] || []).each { |t| tags[t['Key']] = t['Value'] }

        {
          internal_ip: instance['PrivateIpAddress'],
          public_ip: instance['PublicIpAddress'] || instance['PrivateIpAddress'],
          user: tags['cluster-default-user'] || default_user,
          id: instance['InstanceId'],
          services: {
            frontend: {
              redirect_to_https: true
            }
          }
        }
      end

      # Load cluster definition from CloudFormation stack outputs
      # This is the main function that provides the same interface as load_named_cluster_def
      # It combines data from the instance stack and the associated routing stack (for dev boxes)
      # or uses ASG discovery (for production clusters)
      #
      # Uses parallel fetching for independent API calls to improve performance
      def load_from_stack(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'

        $logger.info "Loading cluster definition from CloudFormation stack: #{stack_name}" if $logger

        # Parallel fetch: stack outputs and instances (independent calls)
        outputs = nil
        instances = []
        routing_stack = nil

        threads = []
        threads << Thread.new { outputs = get_stack_outputs(stack_name, region) }
        threads << Thread.new { instances = get_stack_instances(stack_name, region) }
        threads << Thread.new { routing_stack = find_routing_stack(stack_name, region) }
        threads.each(&:join)

        if outputs.empty?
          raise Zapt::Error.new("CloudFormation stack '#{stack_name}' not found or has no outputs")
        end

        # Check for ASG-based instances (parallel fetch already done for CF instances)
        asg_name = outputs['AutoScalingGroupName']
        if asg_name && instances.empty?
          $logger.info "Found ASG: #{asg_name}, discovering instances..." if $logger
          instances = get_asg_instances(asg_name, region)
        end

        if instances.empty?
          raise Zapt::Error.new("No running instances found in stack '#{stack_name}'")
        end

        # Get routing info if routing stack found
        routing_info = {}
        if routing_stack
          routing_info = get_routing_info(routing_stack, region)
          $logger.info "Found routing stack: #{routing_stack}" if $logger
        end

        # Get first instance for default values
        first_instance = instances.first
        first_tags = {}
        (first_instance['Tags'] || []).each { |t| first_tags[t['Key']] = t['Value'] }

        # Determine environment
        env = outputs['ClusterEnv'] || first_tags['env'] || 'development'
        is_production = (env == 'production')

        # Get RTP hosts (from SSM for production, routing stack for dev)
        rtp_hosts = if is_production
          get_prod_rtp_channel_hosts(region)
        else
          routing_info[:rtp_channel_hosts] || parse_rtp_hosts(outputs['ClusterRtpChannelHosts'] || first_tags['cluster-rtp-channel-hosts'])
        end

        # Build cluster definition hash matching YAML structure
        # Priority: routing stack > stack outputs > instance tags > defaults
        cluster_def = {
          name: outputs['ClusterName'] || stack_name,
          region: outputs['ClusterRegion'] || region,
          stacks: stack_name,
          vpc: outputs['ClusterVpc'] || first_instance['VpcId'],
          env: env,
          staging_area: outputs['ClusterStagingArea'] || first_tags['cluster-staging-area'] || stack_name,
          key: outputs['ClusterKey'] || first_tags['cluster-key'] || first_instance['KeyName'],
          cluster_type: 'ec2',
          is_admin: false,
          site_dbname: outputs['ClusterSiteDbname'] || first_tags['cluster-site-dbname'],
          # frontend_host: routing stack for dev, stack output for prod
          frontend_host: routing_info[:frontend_host] || outputs['ClusterFrontendHost'] || first_tags['cluster-frontend-host'],
          rtp_channel_hosts: rtp_hosts,
          nodes: [],
          bins: nil,
          debug: is_production ? {
            bypass_varnish: false,
            disable_app_cache: false,
            disable_health_monitor: false
          } : {
            bypass_varnish: true,
            disable_app_cache: true,
            disable_health_monitor: true
          }
        }

        # Build nodes array
        default_user = outputs['ClusterDefaultUser'] || 'ubuntu'
        instances.each do |instance|
          cluster_def[:nodes] << build_node_from_instance(instance, default_user)
        end

        # Generate site_dbname if not set
        cluster_def[:site_dbname] ||= "wootmath_site_#{cluster_def[:env]}_#{stack_name}"

        # Generate frontend_host if not set
        cluster_def[:frontend_host] ||= "https://#{stack_name}.wootmath.com"

        $logger.info "Loaded cluster '#{cluster_def[:name]}' with #{cluster_def[:nodes].length} node(s) from CloudFormation" if $logger

        cluster_def
      end

      # Parse RTP hosts into the expected hash structure
      def parse_rtp_hosts(rtp_input)
        return nil if rtp_input.nil?
        return nil if rtp_input.is_a?(String) && rtp_input.empty?

        # Already a hash - normalize to symbol keys
        if rtp_input.is_a?(Hash)
          return {
            A: Array(rtp_input[:A] || rtp_input['A']),
            B: Array(rtp_input[:B] || rtp_input['B'])
          }
        end

        # Try to parse as JSON first (handles complex A/B structures)
        if rtp_input.start_with?('{')
          begin
            parsed = JSON.parse(rtp_input)
            return {
              A: Array(parsed['A']),
              B: Array(parsed['B'])
            }
          rescue JSON::ParserError
            # Fall through to simple URL handling
          end
        end

        # Simple URL string -> same URL for both A and B channels
        if rtp_input.start_with?('https://')
          return {
            A: [rtp_input],
            B: [rtp_input]
          }
        end

        # Unknown format
        nil
      end
    end
  end
end
