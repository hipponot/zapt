require 'rubygems'
require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class GemTask < Task

    def initialize args
    end

    def names names, action:install
      names.each{ |name| gem_op(name, action)}
    end

    def name name, action:install
      gem_op(name, action)
    end

    private

    def gem_op name, action
      case action
      when :install
        Zapt.system("gem #{@action} #{name}") unless is_installed? name
      end
    end
    
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


