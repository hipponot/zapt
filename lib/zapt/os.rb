require 'rbconfig'

module Zapt
  @os ||= RbConfig::CONFIG['host_os']
  class << self
    attr_reader :os            
    def is_osx
      self.os =~ /darwin/
    end

    def is_linux
      self.os =~ /linux/
    end
  end
end
