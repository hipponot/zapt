require_relative "zapt/version"
require_relative "zapt/delegator"
require_relative "zapt/logger"
require_relative "zapt/user"

# top level require puts the DSL methods into main scope
include Zapt::Delegator

module Zapt
  # friendly errors
  class Error < StandardError; end

  # class instance methods
  class << self

    def message msg
      $logger.info(msg)
    end

    def error msg
      raise Zapt::Error.new(msg)
    end

    def set_logger_level level
      $logger.level = level
    end

    def load_and_eval filename, *args
      raise Error.new("Can't stat file #{filename}") unless File.exist?(filename)
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


