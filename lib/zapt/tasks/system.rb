require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt

  class System < Task

    attr_accessor :cmds

    def initialize
      @cmds ||= []
    end

    def commands cmds
      @cmds.concat(cmds)
    end

    def command cmd
      @cmds << cmd
    end

    def run
      @cmds.each{ |c| Zapt.system(c) }
    end

  end
end


