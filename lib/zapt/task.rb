module Zapt
  class Task

    attr_reader :name
    attr_reader :desc

    def initialize name:'anon', desc:'a zapt task'
      @name = name
      @desc = desc
    end

  end
end
