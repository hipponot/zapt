require_relative 'version'

class String
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

module Zapt
  class Tasks

    @zapt_cli = false;    
    @registry = {}
    class << self
      # running zapt naked or via zapt cli ?
      attr_accessor :zapt_cli
      attr_accessor :registry
      # This method defines a Tasks instance method that instance eval's the provided block
      # in the implementation context (e.g. package -> Package.new.instance_eval(&block)
      def define_task task_name
        define_method(task_name) do |args={}, &block|
          # instantiate class from string (there has to be a better way!)
          task = "Zapt::#{task_name.camel_case}Task".split('::').inject(Object) {|o,c| o.const_get c}.new(args)
          if Tasks.zapt_cli
            # shorthand for open eigenclass and define method
            task.define_singleton_method('run') {
              self.instance_eval &block unless block.nil?
            }
            register(task)
          else
            task.instance_eval &block unless block.nil?
          end
        end
      end
    end

    def register task
      @ntask ||= 0
      task_name = task.task_name == 'anon' ? task.task_name + "_" + Tasks.registry.count.to_s : task.task_name
      Tasks.registry[task_name] = task
    end

    # require all tasks
    root = File.dirname(File.absolute_path(__FILE__))
    Dir.glob(root + '/tasks/*.rb') do |task|
      require task
      Tasks.define_task File.basename(task, '_task.rb')
    end

  end
end
