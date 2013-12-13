require 'json'
require 'yaml'
require_relative '../../zapt'

module Zapt

  class CLI < Thor
    desc "runtask", "run the tasks specified in runlist"
    method_option :tasks, :aliases => "-t", :type=>:string, :default=>'tasks.rb', :required=>false, :desc => "Task file"
    method_option :runlist, :aliases => "-r", :type=>:array, :required=>true, :desc => "Run list"
    method_option :cluster, :aliases => "-c", :type=>:string, :required=>false, :desc => "Specify cluster on which to run task"
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
          nodes = YAML::load(IO.read(cluster))[:nodes]
          nodes.each do |node|
            "running #{task.task_name} on #{node[:public_ip]}"
            remote_task = ShellTask.new({})
            remote_dir = File.dirname(File.join('zcripts', File.expand_path('tasks.rb').split('zcripts/')[1]))
            if options[:arglist]
              remote_task.command "cd #{remote_dir}; rvmsudo zapt runtask -r #{task.task_name} -a \"#{options[:arglist]}\"", host:node[:public_ip], user:node[:user]
            else
              remote_task.command "cd #{remote_dir}; rvmsudo zapt runtask -r #{task.task_name}", host:node[:public_ip], user:node[:user]
            end
          end
        else
          "running #{task}"
          $logger.info "running #{task}"
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
