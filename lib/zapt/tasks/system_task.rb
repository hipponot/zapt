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

    def commands cmds, working_dir:ENV['HOME'], user:nil
      cmds.each do |cmd| 
        run_cmd cmd, working_dir, user
      end
    end

    def command cmd, working_dir:ENV['HOME'], user:nil
      run_cmd cmd, working_dir, user
    end

    private 
    
    def run_cmd cmd, working_dir, user
      cmd.insert(0,"cd #{working_dir};")
      Zapt.system(cmd, user) 
    end

  end
end


