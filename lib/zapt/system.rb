require 'open3'

USE_BACKTICKS = true


module Zapt
  class << self
  def system cmd, user=nil, host=nil, pem=nil, quiet=false, ignore_failure=false, capture=true
    # switch user
    if user and !host
      cmd = "sudo su #{user} -l -c \"#{cmd}\""
      #ToDo: use ipaddr private? when we upgrade to 2.5.x or better
    # run on remove host with no pem
    elsif  host && pem.nil?
      cmd = "ssh -tt -q -o \"StrictHostKeyChecking no\" #{user}@#{host} \"#{cmd}\""
    # run on remove host with pem
    elsif host
      cmd = "ssh -tt -q -o \"StrictHostKeyChecking no\" -o \"ForwardAgent yes\" -i #{pem} #{user}@#{host} \"#{cmd}\""
    end
    rval = ""
    exit_status = nil
    $logger.info "Running command: #{cmd}" unless quiet
    # alternatively use Open3.capture3 (this caused hangs but maybe -tt fixed the issue?)
    if USE_BACKTICKS
      rval = `#{cmd}`; exit_status=($?.exitstatus == 0)
      if(exit_status)
        $logger.info(rval) unless quiet;
      else
        $logger.error(rval) unless ignore_failure
      end
      puts rval if $logger.disabled
    else
      Open3::popen3(cmd) do |stdin, stdout, stderr, status|
        stdout.each do |line|
          $logger.info line.chomp unless quiet
          stdout.flush
          rval += line
        end
        stderr.each do |line|
          $logger.warn line.chomp
          stderr.flush
        end
        exit_status = status.value.success?
      end
    end
    return rval, exit_status
  end
end
end

