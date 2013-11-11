require_relative '../zapt'
module Zapt
  def self.with_friendly_errors
    begin
      yield
    rescue Zapt::Error => e
      Zapt.ui.error e.message
      Zapt.ui.debug e.backtrace.join("\n")
      exit 1
    rescue Interrupt => e
      Zapt.ui.error "\nQuitting..."
      Zapt.ui.debug e.backtrace.join("\n")
      exit 1
    rescue SystemExit => e
      exit e.status
    rescue Exception => e
      Zapt.ui.error(
        "Unfortunately, a fatal error has occurred.")
      raise e
    end
  end
end

