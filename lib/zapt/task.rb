module Zapt
  class Task

    attr_reader :task_name
    attr_reader :task_desc

    def initialize name:'anon', desc:'a zapt task'
      @task_name = name
      @task_desc = desc
    end

    def message msg
      Zapt.message msg
    end

  end
end
