require 'rubygems'
require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class Gem < Task

    attr_accessor :gems
    attr_accessor :action

    def initialize
      self.gems ||= []
      self.action ||= 'install'
    end

    def names value
      self.gems.concat(value)
    end

    def name value
      self.gems << value
    end

    def run
      gems.each do |gem|
        Zapt.system("gem #{self.action} #{gem}") unless is_installed? gem
      end
    end

    private
    
    def is_installed? name, version=nil
      begin
        if (version.nil?)
          ::Gem::Specification.find_by_name(name)
        else
          ::Gem::Specification.find_by_name(name, version)
        end
        true
      rescue ::Gem::LoadError 
        false
      end
    end


  end
end


