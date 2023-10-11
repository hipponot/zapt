require 'json'
require 'yaml'
require_relative '../../zapt'

module Zapt

  class CLI < Thor
    desc "runtask", "run the tasks specified in runlist"
    method_option :tasks, :aliases => "-t", :type=>:string, :default=>'tasks.rb', :required=>false, :desc => "Task file"
    method_option :runlist, :aliases => "-r", :type=>:array, :required=>true, :desc => "Run list"
    method_option :cluster, :aliases => "-c", :type=>:string, :required=>false, :desc => "Specify cluster on which to run task"
    method_option :pem, :aliases => "-p", :type=>:string, :required=>false, :default=>"~/.ssh/dev-test-key.pem", :desc => "Remote command PEM"
    method_option :capture, :type=>:boolean, :required=>false, :desc => "bypass logging and capture output to stdout"
    def runtask

      raise Error.new("arglist length > runlist length") if options[:arglist] and options[:arglist].length > options[:runlist].length

      task_file = options[:tasks]
      Zapt.load_and_eval task_file

      options[:runlist].each_with_index do |task, i|
        taskargs = options[:arglist] ? (parse_args options[:arglist][i]) : {}
        $logger.error("No such task #{task}") and exit(1) unless Zapt::Tasks.registry.has_key? task

        if options[:cluster]
          cluster = options[:cluster]
          $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster)
          task = Zapt::Tasks.registry[task]
          cluster_config = YAML::load(IO.read(cluster))

          # pem from top level cluster config
          pem = "#{ENV['HOME']}/credentials/#{cluster_config[:key]}.pem"

          nodes = cluster_config[:nodes]
          nodes.each_with_index do |node|
            ip = Zapt.ip_from_node(node)
            user = node[:user]
            "Running task: #{task.task_name} on #{ip}"
            remote_task = ShellTask.new({})
            remote_dir = File.dirname(File.join('zcripts', File.expand_path('tasks.rb').split('zcripts/')[1]))
            if options[:arglist]
              args = options[:arglist][i]
              remote_task.command(%Q{cd #{remote_dir}; rvmsudo_secure_path=1 rvmsudo zapt runtask -r #{task.task_name} -a \\"#{args}\\"}, host:ip, user:user, pem:pem, capture:options[:capture])
            else
              remote_task.command "cd #{remote_dir}; rvmsudo_secure_path=1 rvmsudo zapt runtask -r #{task.task_name}", host:ip, user:user, pem:pem, capture:options[:capture]
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

  end

end
