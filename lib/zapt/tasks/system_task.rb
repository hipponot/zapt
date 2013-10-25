require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative 'common/dir'

module Zapt

  class SystemTask < Task

    include Zapt::Common::Dir

    attr_accessor :cmds
    def initialize args
      @cmds ||= []
    end

    def commands cmds
      @cmds.concat(cmds)
    end

    def command cmd
      @cmds << cmd
    end

    def run
      @cmds.each do |c| 
        c.insert(0,"cd #{@dir};") if @dir
        Zapt.system(c) 
      end
    end

  end
end


