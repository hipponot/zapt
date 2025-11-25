# CloudFormation-based cluster definition loader for zapt
# This module provides functions to load cluster definitions from CloudFormation
# stack outputs and EC2 instance tags instead of YAML files.
#
# Usage:
#   Set CLUSTER_DEF_SOURCE=cloudformation to use CF-based loading
#   Or call Zapt::ClusterDefCF.load_from_stack(stack_name) directly
#
require 'json'

module Zapt
  module ClusterDefCF
    # Production RTP channel hosts configuration
    # These are static since production comms servers are fixed infrastructure
    PROD_RTP_CHANNEL_HOSTS = {
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
      # Check if we should use CloudFormation-based loading
      def use_cloudformation?
        ENV['CLUSTER_DEF_SOURCE'] == 'cloudformation'
      end

      # Get the current instance's metadata using IMDSv2
      def get_instance_metadata(path)
        # Get token for IMDSv2
        token = `curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null`.strip
        return nil if token.empty?

        # Use token to get metadata
        result = `curl -s -H "X-aws-ec2-metadata-token: #{token}" "http://169.254.169.254/latest/meta-data/#{path}" 2>/dev/null`.strip
        result.empty? ? nil : result
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
        cmd = "aws ec2 describe-tags --filters \"Name=resource-id,Values=#{instance_id}\" --region #{region} --output json 2>/dev/null"
        result = `#{cmd}`
        return {} if result.empty?

        tags = {}
        JSON.parse(result)['Tags'].each do |tag|
          tags[tag['Key']] = tag['Value']
        end
        tags
      rescue JSON::ParserError
        {}
      end

      # Get CloudFormation stack outputs
      def get_stack_outputs(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cmd = "aws cloudformation describe-stacks --stack-name #{stack_name} --region #{region} --output json 2>/dev/null"
        result = `#{cmd}`
        return {} if result.empty?

        outputs = {}
        stack = JSON.parse(result)['Stacks']&.first
        return {} unless stack

        (stack['Outputs'] || []).each do |output|
          outputs[output['OutputKey']] = output['OutputValue']
        end
        outputs
      rescue JSON::ParserError
        {}
      end

      # Get CloudFormation stack parameters
      def get_stack_parameters(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'
        cmd = "aws cloudformation describe-stacks --stack-name #{stack_name} --region #{region} --output json 2>/dev/null"
        result = `#{cmd}`
        return {} if result.empty?

        params = {}
        stack = JSON.parse(result)['Stacks']&.first
        return {} unless stack

        (stack['Parameters'] || []).each do |param|
          params[param['ParameterKey']] = param['ParameterValue']
        end
        params
      rescue JSON::ParserError
        {}
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
        cmd = "aws ec2 describe-instances --filters \"Name=tag:aws:cloudformation:stack-name,Values=#{stack_name}\" \"Name=instance-state-name,Values=running\" --region #{region} --output json 2>/dev/null"
        result = `#{cmd}`
        return [] if result.empty?

        instances = []
        JSON.parse(result)['Reservations'].each do |reservation|
          reservation['Instances'].each do |instance|
            instances << instance
          end
        end
        instances
      rescue JSON::ParserError
        []
      end

      # Get all EC2 instances in an AutoScaling Group
      def get_asg_instances(asg_name, region = nil)
        region ||= get_current_region || 'us-west-2'

        # First get instance IDs from the ASG
        asg_cmd = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names #{asg_name} --region #{region} --output json 2>/dev/null"
        asg_result = `#{asg_cmd}`
        return [] if asg_result.empty?

        asg_data = JSON.parse(asg_result)
        asg = asg_data['AutoScalingGroups']&.first
        return [] unless asg

        instance_ids = asg['Instances']&.select { |i| i['LifecycleState'] == 'InService' }&.map { |i| i['InstanceId'] }
        return [] if instance_ids.nil? || instance_ids.empty?

        # Then get full instance details
        ids_str = instance_ids.join(' ')
        ec2_cmd = "aws ec2 describe-instances --instance-ids #{ids_str} --region #{region} --output json 2>/dev/null"
        ec2_result = `#{ec2_cmd}`
        return [] if ec2_result.empty?

        instances = []
        JSON.parse(ec2_result)['Reservations'].each do |reservation|
          reservation['Instances'].each do |instance|
            instances << instance if instance['State']['Name'] == 'running'
          end
        end
        instances
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
      def load_from_stack(stack_name, region = nil)
        region ||= get_current_region || 'us-west-2'

        $logger.info "Loading cluster definition from CloudFormation stack: #{stack_name}" if $logger

        # Get stack outputs
        outputs = get_stack_outputs(stack_name, region)
        if outputs.empty?
          raise Zapt::Error.new("CloudFormation stack '#{stack_name}' not found or has no outputs")
        end

        # Get instances - try ASG first (for production clusters), then CF stack instances (for dev boxes)
        instances = []
        asg_name = outputs['AutoScalingGroupName']
        if asg_name
          $logger.info "Found ASG: #{asg_name}, discovering instances..." if $logger
          instances = get_asg_instances(asg_name, region)
        end

        # Fall back to CF stack instances if no ASG or no ASG instances found
        if instances.empty?
          instances = get_stack_instances(stack_name, region)
        end

        if instances.empty?
          raise Zapt::Error.new("No running instances found in stack '#{stack_name}'")
        end

        # Try to find associated routing stack for frontend_host and rtp_channel_hosts (dev boxes)
        routing_stack = find_routing_stack(stack_name, region)
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
          # rtp_channel_hosts: production uses static config, dev uses routing stack
          rtp_channel_hosts: is_production ? PROD_RTP_CHANNEL_HOSTS : (routing_info[:rtp_channel_hosts] || parse_rtp_hosts(outputs['ClusterRtpChannelHosts'] || first_tags['cluster-rtp-channel-hosts'])),
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
