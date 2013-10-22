require 'popen4'
module Zapt
  class << self

    def system cmd
      $logger.info "Running: #{cmd}"
      status = POpen4::popen4( cmd ) do |stdout, stderr, stdin|
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
