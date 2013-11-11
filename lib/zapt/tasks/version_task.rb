require_relative '../task'
require_relative '../version'

module Zapt

  class VersionTask < Task

    def initialize args
      super
    end

    def run
      Zapt::VERSION
    end
  end

end

