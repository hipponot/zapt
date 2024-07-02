require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative 'common/dir'
require_relative 'filesystem_task'

module Zapt

  class ShellTask < FilesystemTask

    include Zapt::Common::Dir

    attr_accessor :cmds
    def initialize args
      super
    end

    def commands cmds, working_dir:nil, user:nil, host:nil, pem:nil, quiet:false, ignore_failure:false, dryrun:false, capture:false
      rval = []
      cmds.each do |cmd|
        rval << run_cmd(cmd, working_dir, user, host, pem, quiet, dryrun, ignore_failure, capture)
      end
    end

    def command cmd, working_dir:nil, user:nil, host:nil, pem:nil, quiet:false, ignore_failure:false, dryrun:false, capture:false
      rval, status = run_cmd cmd, working_dir, user, host, pem, quiet, dryrun, ignore_failure, capture
      raise Error.new "Command bad exit status #{cmd}" unless status or ignore_failure
      return rval, status
    end

    private

    def run_cmd cmd, working_dir, user, host, pem, quiet, dryrun, ignore_failure, capture
      cmd.insert(0,"cd #{working_dir};") if working_dir
      return Zapt.system(cmd, user, host, pem, quiet, ignore_failure, capture) unless dryrun
      puts "dryrun: #{cmd}"
      return nil, 0
    end

  end
end
