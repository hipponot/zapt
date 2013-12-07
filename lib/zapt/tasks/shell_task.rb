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

    def commands cmds, working_dir:nil, user:nil, host:nil, quiet:false
      rval = []
      cmds.each do |cmd| 
        rval << run_cmd(cmd, working_dir, user, host, quiet)
      end
    end

    def command cmd, working_dir:nil, user:nil, host:nil, quiet:false
      return run_cmd cmd, working_dir, user, host, quiet
    end

    private 
    
    def run_cmd cmd, working_dir, user, host, quiet
      cmd.insert(0,"cd #{working_dir};") if working_dir
      return Zapt.system(cmd, user, host, quiet)
    end

  end
end


