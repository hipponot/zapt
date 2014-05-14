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

    def commands cmds, working_dir:nil, user:nil, host:nil, pem:"~/credentials/wootmath_ec2_hosts.pem", quiet:false, ignore_failure:false
      rval = []
      cmds.each do |cmd| 
        rval << run_cmd(cmd, working_dir, user, host, pem, quiet)
      end
    end

    def command cmd, working_dir:nil, user:nil, host:nil, pem:"~/credentials/wootmath_ec2_hosts.pem", quiet:false, ignore_failure:false
      rval, status = run_cmd cmd, working_dir, user, host, pem, quiet
      raise Error.new "Command bad exit status #{cmd}" unless status or ignore_failure
      return rval, status
    end

    private 
    
    def run_cmd cmd, working_dir, user, host, pem, quiet
      cmd.insert(0,"cd #{working_dir};") if working_dir
      return Zapt.system(cmd, user, host, pem, quiet)
    end

  end
end


