require 'etc'

module Zapt

  class << self
    def home
      File.expand_path(File.join(File.dirname(__FILE__), '..','..'))
    end

    def bin
      File.join(Zapt.home, 'bin')
    end
  end  
  

end
