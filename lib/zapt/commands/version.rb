require_relative '../version'

module Zapt

  class CLI < Thor
    desc "version", "print version"
    def version
      puts VERSION
    end
  end

end
