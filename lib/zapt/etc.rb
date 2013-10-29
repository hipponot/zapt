require 'etc'

module Zapt

  class << self
    def home
      File.expand_path(File.join(File.dirname(__FILE__), '..','..'))
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
