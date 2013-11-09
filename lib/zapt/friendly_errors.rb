module Zapt
  def self.with_friendly_errors
    begin
      yield
    rescue Woot::Error => e
      WootBank.ui.error e.message
      WootBank.ui.debug e.backtrace.join("\n")
      exit 1
    rescue Interrupt => e
      WootBank.ui.error "\nQuitting..."
      WootBank.ui.debug e.backtrace.join("\n")
      exit 1
    rescue SystemExit => e
      exit e.status
    rescue Exception => e
      WootBank.ui.error(
        "Unfortunately, a fatal error has occurred.")
      raise e
    end
  end
end

