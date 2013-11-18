require_relative '../../zapt'
module Zapt

  class CLI < Thor
    desc "runtask", "run the tasks specified in runlist"
    method_option :tasks, :aliases => "-t", :type=>:string, :default=>'tasks.rb', :required=>false, :desc => "Task file"
    method_option :runlist, :aliases => "-r", :type=>:array, :required=>true, :desc => "Run list"
    def runtask
      # quiet zapt for this command
      task_file = options[:tasks]
      Zapt.load_and_eval task_file
      options[:runlist].each do |task|
        unless Zapt::Tasks.registry.has_key? task
          $logger.error("No such task #{task}")
          exit(1)
        end
        "running #{task}"
        $logger.info "running #{task}"
        Zapt::Tasks.registry[task].run
      end
    end
  end

end
