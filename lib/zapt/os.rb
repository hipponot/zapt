require 'rbconfig'

module Zapt
  @os ||= RbConfig::CONFIG['host_os']
  class << self
    attr_reader :os            

    def is_osx
      self.os =~ /darwin/
    end

    def is_ubuntu
      self.os =~ /ubuntu/
    end

  end
  
end
