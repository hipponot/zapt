require 'open3'
module Zapt
  class << self

    def system cmd, user=nil, host=nil, quiet=false
      cmd = "sudo su #{user} -l -c \"#{cmd}\"" if user and !host
      cmd = "ssh -o \"StrictHostKeyChecking no\" -i ~/credentials/wootmath_ec2_hosts.pem #{user}@#{host} \'#{cmd}\'" if host
      rval = ""
      $logger.info "Running: #{cmd}"
      status = Open3::popen3(cmd) do |stdin, stdout, stderr|
        stdout.each do |line|
          $logger.info line.chomp unless quiet
          rval += line.chomp
        end
        stderr.each do |line|
          $logger.warn line.chomp
        end
      end
      return rval
    end

  end
end
