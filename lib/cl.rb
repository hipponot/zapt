require_relative "zapt/ui"

module Zapt

  class << self
    attr_writer :ui
    def ui
      @ui ||= UI.new
    end
  end

end

