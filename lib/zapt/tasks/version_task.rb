require_relative '../task'
require_relative '../version'

module Zapt

  class VersionTask < Task
    def run
      Zapt::VERSION
    end
  end

end

