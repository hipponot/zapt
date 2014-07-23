require 'erubis'

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

    def commands cmds, working_dir:nil, user:nil, host:nil, pem:"~/credentials/wootmath_ec2_hosts.pem", quiet:false, ignore_failure:false, dryrun:false
      rval = []
      cmds.each do |cmd| 
        rval << run_cmd(cmd, working_dir, user, host, pem, quiet, dryrun)
      end
    end

    def command cmd, working_dir:nil, user:nil, host:nil, pem:"~/credentials/wootmath_ec2_hosts.pem", quiet:false, ignore_failure:false, dryrun:false
      rval, status = run_cmd cmd, working_dir, user, host, pem, quiet, dryrun
      raise Error.new "Command bad exit status #{cmd}" unless status or ignore_failure
      return rval, status
    end

    def erb source, target, owner:nil, group:nil, mode:nil
      eruby = Erubis::Eruby.new(IO.read(source))
      IO.write(target, eruby.result(binding()))
      file_operation(nil, target, nil, owner, group, mode)
    end

    private 
    
    def run_cmd cmd, working_dir, user, host, pem, quiet, dryrun
      cmd.insert(0,"cd #{working_dir};") if working_dir
      return Zapt.system(cmd, user, host, pem, quiet) unless dryrun
      puts "dryrun: #{cmd}"
      return nil, 0
    end

  end
end


