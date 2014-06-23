require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class PackageTask < Task

    attr_accessor :packages
    attr_accessor :action

    def initialize args
      super
    end

    def names values, action:'install', provider:'apt'
      values.each do |pkg|
        package_action pkg, action, provider
      end
    end

    def name value, action:'install', provider:'apt'
      package_action value, action, provider
    end
    
    private
    
    def package_action pkg, action, provider
      case provider
      when 'brew'
        brew_action(pkg, action)
      when 'apt'
        apt_action(pkg, action)
      when 'gem'
        gem_action(pkg, action)
      end
    end

    def gem_action pkg, action
      Zapt.system("gem #{action} -f --no-ri --no-rdoc  #{pkg}")
    end

    def apt_action pkg, action
      Zapt.system("sudo apt-get #{action} -qq #{pkg}")
    end

    def brew_action pkg, action
      Zapt.system("brew #{action} #{pkg}")
    end

  end
end


