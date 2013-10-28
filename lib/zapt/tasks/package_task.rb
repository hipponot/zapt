require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class PackageTask < Task

    attr_accessor :packages
    attr_accessor :action

    def initialize args
    end

    def names values, action:'install'
      values.each do |pkg|
        package_action pkg, action
      end
    end

    def name value, action:'install'
      package_action value, action
    end
    
    private
    
    def package_action pkg, action
      if Zapt.is_osx
        brew_action(pkg, action)
      elsif Zapt.is_linux
        apt_action(pkg, action)
      end
    end

    def apt_action pkg, action
      Zapt.system("sudo apt-get #{action} -qq #{pkg}")
    end

    def brew_action pkg, action
      Zapt.system("brew #{action} #{pkg}")
    end

  end
end


