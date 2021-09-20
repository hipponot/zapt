require 'open3'

module Zapt

  class << self
    
    def system cmd, user=nil, host=nil, pem=nil, quiet=false
      if user and !host
        cmd = "sudo su #{user} -l -c \"#{cmd}\""
      elsif user = 'ubuntu' 
        cmd = "ssh -o \"StrictHostKeyChecking no\" -i #{pem} #{user}@#{host} \"#{cmd}\"" if host
      elsif  /[(10)|(192)]\.\d+\.\d+\.\d+/ =~ host || user=='vagrant'
        cmd = "ssh -o \"StrictHostKeyChecking no\" vagrant@#{host} \"#{cmd}\"" if host
      else
        cmd = "ssh -o \"StrictHostKeyChecking no\" -i #{pem} #{user}@#{host} \"#{cmd}\"" if host
      end
      rval = ""
      exit_status = nil
      $logger.info "Running command: #{cmd}" unless quiet
      rval = `#{cmd}`; exit_status=($?.exitstatus == 0)
      if(exit_status)
        $logger.info(rval);
      else
        $logger.error(rval);
      end
      # Boo - this causes HANGs over ssh (was trying to get it to flush output line by line)
      # Open3::popen3(cmd) do |stdin, stdout, stderr, status|
      #   stdout.each do |line|
      #     $logger.info line.chomp unless quiet
      #     stdout.flush
      #     rval += line
      #   end
      #   stderr.each do |line|
      #     $logger.warn line.chomp
      #     stderr.flush
      #   end
      #   exit_status = status.value.success?
      # end
      return rval, exit_status
    end
  end
end

