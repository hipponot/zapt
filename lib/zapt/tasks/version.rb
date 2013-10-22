require_relative '../task'
require_relative '../version'

module Zapt

  class Version < Task
    def run
      Zapt::VERSION
    end
  end

end

