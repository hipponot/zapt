require_relative '../zapt'
module Zapt
  def self.with_friendly_errors
    begin
      yield
    rescue Zapt::Error => e
      $logger.error e.message
      $logger.debug e.backtrace.join("\n")
      $fail = true
      exit 1
    rescue Interrupt => e
      $logger.error "\nQuitting..."
      $logger.debug e.backtrace.join("\n")
      $fail = true
      exit 1
    rescue SystemExit => e
      $logger.error e.message
      $fail = true
      exit e.status
    rescue Exception => e
      $logger.error("Unfortunately, a fatal error has occurred #{e.message}")
      $fail = true
      exit 1
    end
  end
end

