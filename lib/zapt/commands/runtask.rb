require 'json'
require 'yaml'
require_relative '../../zapt'
require_relative '../cluster_def_cf'

module Zapt

  class CLI < Thor
    desc "runtask", "run the tasks specified in runlist"
    method_option :tasks, :aliases => "-t", :type=>:string, :default=>'tasks.rb', :required=>false, :desc => "Task file"
    method_option :runlist, :aliases => "-r", :type=>:array, :required=>true, :desc => "Run list"
    method_option :cluster, :aliases => "-c", :type=>:string, :required=>false, :desc => "Specify cluster on which to run task (YAML file or stack name)"
    method_option :pem, :aliases => "-p", :type=>:string, :required=>false, :default=>"~/.ssh/dev-test-key.pem", :desc => "Remote command PEM"
    method_option :capture, :type=>:boolean, :required=>false, :desc => "bypass logging and capture output to stdout"
    def runtask

      raise Error.new("arglist length > runlist length") if options[:arglist] and options[:arglist].length > options[:runlist].length

      task_file = options[:tasks]
      Zapt.load_and_eval task_file

      $logger.disabled = options[:capture]

      options[:runlist].each_with_index do |task, i|
        taskargs = options[:arglist] ? (parse_args options[:arglist][i]) : {}
        $logger.error("No such task #{task}") and exit(1) unless Zapt::Tasks.registry.has_key? task

        if options[:cluster]
          cluster = options[:cluster]
          task = Zapt::Tasks.registry[task]

          # Load cluster config - try CloudFormation first, then YAML file
          cluster_config = load_cluster_config(cluster)

          # pem from top level cluster config
          pem = "#{ENV['HOME']}/credentials/#{cluster_config[:key]}.pem"

          nodes = cluster_config[:nodes]

          # Pass stack name to remote tasks so they can load cluster def from CloudFormation
          # This is needed because remote instances may not have CF stack tags
          # Use cluster_config[:name] (from CF), or extract from cluster path/arg
          cluster_base = cluster.end_with?('.yaml') ? File.basename(cluster, '.yaml') : cluster
          stack_name = cluster_config[:name] || cluster_base

          nodes.each_with_index do |node|
            ip = Zapt.ip_from_node(node)
            user = node[:user]
            "Running task: #{task.task_name} on #{ip}"
            remote_task = ShellTask.new({})
            remote_dir = File.dirname(File.join('zcripts', File.expand_path('tasks.rb').split('zcripts/')[1]))

            # Set CLUSTER_DEF_STACK env var so remote load_cluster_def can find the stack
            # Use sudo env to pass environment variable through to the subprocess
            env_var = "CLUSTER_DEF_STACK=#{stack_name}"

            if options[:arglist]
              args = options[:arglist][i]
              remote_task.command(%Q{cd #{remote_dir}; rvmsudo_secure_path=1 rvmsudo env #{env_var} zapt runtask -r #{task.task_name} -a \\"#{args}\\"}, host:ip, user:user, pem:pem)
            else
              remote_task.command %Q{cd #{remote_dir}; rvmsudo_secure_path=1 rvmsudo env #{env_var} zapt runtask #{options[:capture] ? '--capture' : ''} -r #{task.task_name}}, host:ip, user:user, pem:pem
            end
          end
        else
          $logger.info "Running task: #{task}"
          task = Zapt::Tasks.registry[task]
          task.taskargs = taskargs
          task.run
        end
      end
    end

    private

    def parse_args string
      begin
        args = eval(string)
      rescue
        args = JSON.parse(string)
      rescue
        args = YAML.load(string)
      end
      args ||= {}
    end

    # Load cluster configuration from CloudFormation or YAML file
    # Supports:
    #   - CloudFormation stack name (e.g., "jward", "snapper-box")
    #   - YAML file path (e.g., "/path/to/cluster.yaml")
    # Environment variable CLUSTER_DEF_SOURCE controls behavior:
    #   - 'cloudformation': Only try CloudFormation
    #   - 'yaml': Only try YAML file
    #   - 'auto' (default): Try CloudFormation first, fall back to YAML
    def load_cluster_config(cluster)
      source = ENV['CLUSTER_DEF_SOURCE'] || 'auto'

      # Extract cluster name from path if it's a YAML file path
      if cluster.end_with?('.yaml')
        cluster_name = File.basename(cluster, '.yaml')
        yaml_path = cluster
      else
        cluster_name = cluster
        yaml_path = nil
      end

      # Try CloudFormation first (unless explicitly set to yaml)
      if source == 'cloudformation' || source == 'auto'
        begin
          cluster_config = Zapt::ClusterDefCF.load_from_stack(cluster_name)
          return cluster_config
        rescue Zapt::Error => e
          if source == 'cloudformation'
            raise e
          end
          # Auto mode: fall through to YAML
          $logger.info "CloudFormation loading failed (#{e.message}), falling back to YAML" if $logger
        end
      end

      # Fall back to YAML file
      if yaml_path.nil?
        # Try to find YAML file in common locations
        possible_paths = [
          cluster_name,
          "#{cluster_name}.yaml",
          File.join(Dir.pwd, 'cluster_defs', "#{cluster_name}.yaml"),
          File.join(Dir.pwd, '..', 'common', 'cluster_defs', "#{cluster_name}.yaml")
        ]
        yaml_path = possible_paths.find { |p| File.exist?(p) }
      end

      if yaml_path.nil? || !File.exist?(yaml_path)
        raise Zapt::Error.new("Can't find cluster definition: #{cluster_name} (tried CloudFormation and YAML)")
      end

      $logger.info "Loading cluster from YAML: #{yaml_path}" if $logger
      YAML::load(IO.read(yaml_path))
    end

  end

end
