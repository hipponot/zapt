require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"
require_relative "zapt/user"

# top level require puts the DSL methods into main scope
include Zapt::Delegator
at_exit { $logger.info('...tasks have been Zapt') }

module Zapt
  # friendly errors
  class Error < StandardError; end

  # class instance methods
  class << self

    def message msg
      $logger.info(msg)
    end

    def load_and_eval filename, *args
      proc = Proc.new {}
      eval(File.read(filename), proc.binding, filename)
    end

    def home
      File.expand_path(File.join(File.dirname(__FILE__),'..'))
    end

    def bin
      File.join(Zapt.home, 'bin')
    end

    def ask(statement)
      puts statement.yellow
      gets.tap{|text| text.strip! if text}
    end

  end
end


