require 'rubygems'
require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class Gem < Task

    attr_accessor :gems
    attr_accessor :action

    def initialize
      @gems ||= []
      @action ||= 'install'
    end

    def names value
      @gems.concat(value)
    end

    def name value
      @gems << value
    end

    def run
      gems.each do |gem|
        Zapt.system("gem #{@action} #{gem}") unless is_installed? gem
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


