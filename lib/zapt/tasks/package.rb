require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class Package < Task

    attr_accessor :packages
    attr_accessor :action

    def initialize
      @packages ||= []
      @action ||= 'install'
    end

    def names value
      @packages.concat(value)
    end

    def name value
      @packages << value
    end

    def run
      packages.each do |pkg|
        if Zapt.is_osx
          brew_install(pkg)
        elsif Zapt.is_linux
          apt_install(pkg)
        end
      end
    end
    
    private
    
    def apt_install pkg
      Zapt.system("sudo apt-get #{@action} #{pkg}")
    end

    def brew_install pkg
      Zapt.system("brew #{@action} #{pkg}")
    end

  end
end


