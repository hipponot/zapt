require 'open3'
module Zapt
  class << self

    def system cmd, user=nil
      cmd = "rvmsudo -u #{user} #{cmd}" if user
      $logger.info "Running: #{cmd}"
      status = Open3::popen3(cmd) do |stdin, stdout, stderr|
        stdout.each do |line|
          $logger.info line.chomp
        end
        stderr.each do |line|
          $logger.warn line.chomp
        end
      end
    end

  end
end
