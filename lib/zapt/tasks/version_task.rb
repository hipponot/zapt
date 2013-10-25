require_relative '../task'
require_relative '../version'

module Zapt

  class VersionTask < Task

    def initialize args
    end

    def run
      Zapt::VERSION
    end
  end

end

