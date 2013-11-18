require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative 'common/dir'

module Zapt

  class ShellTask < Task

    include Zapt::Common::Dir

    attr_accessor :cmds
    def initialize args
      super
    end

    def commands cmds, working_dir:nil, user:nil, host:nil
      rval = []
      cmds.each do |cmd| 
        rval << run_cmd(cmd, working_dir, user, host)
      end
    end

    def command cmd, working_dir:nil, user:nil, host:nil
      return run_cmd cmd, working_dir, user, host
    end

    private 
    
    def run_cmd cmd, working_dir, user, host
      cmd.insert(0,"cd #{working_dir};") if working_dir
      return Zapt.system(cmd, user, host) 
    end

  end
end


