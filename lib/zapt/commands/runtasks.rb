require_relative '../../zapt'
module Zapt

  class CLI < Thor
    desc "runtask", "run the tasks specified in runlist"
    method_option :tasks, :aliases => "-t", :type=>:string, :default=>'tasks.rb', :required=>false, :desc => "Task file"
    method_option :runlist, :aliases => "-r", :type=>:array, :required=>true, :desc => "Run list"
    method_option :cluster, :aliases => "-c", :type=>:string, :required=>false, :desc => "Specify cluster on which to run task"
    def runtask
      task_file = options[:tasks]
      Zapt.load_and_eval task_file
      options[:runlist].each do |task|
        $logger.error("No such task #{task}") and exit(1) unless Zapt::Tasks.registry.has_key? task
        if options[:cluster]
          cluster = options[:cluster]
          $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster) 
          task = Zapt::Tasks.registry[task]
          nodes = YAML::load(IO.read(cluster))[:nodes]
          nodes.each do |node|
            "running #{task.task_name} on #{node[:public_ip]}"
            # {} placeholder for args
            remote_task = ShellTask.new({})
            remote_dir = File.dirname(File.join('zcripts', File.expand_path('tasks.rb').split('zcripts/')[1]))
            remote_task.command "cd #{remote_dir}; rvmsudo zapt runtask -r #{task.task_name}", host:node[:public_ip], user:node[:user]
          end
        else
          "running #{task}"
          $logger.info "running #{task}"
          Zapt::Tasks.registry[task].run
        end
      end
    end
  end

end
