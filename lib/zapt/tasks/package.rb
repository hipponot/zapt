require_relative '../task'
require_relative '../os'

module Zapt

  class Package < Task

    attr_accessor :packages
    attr_accessor :action

    def initialize
      self.packages ||= []
      self.action ||= 'install'
    end

    def names value
      self.packages.concat(value)
      puts self.packages
    end

    def name value
      self.packages << value
    end

    def run
      puts Zapt.os
    end
    
  end
end


