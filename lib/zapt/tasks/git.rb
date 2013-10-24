require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt

  class Git < Task

    attr_accessor :repos
    attr_accessor :dir

    def initialize
      @repos ||= []
      @dir = ENV['HOME']
    end

    def repos value
      @repos.concat(value)
    end

    def repo value
      @repos << value
    end

    def dir value
      @dir = value
    end

    def run
      @repos.each do |r|
        target = File.join(@dir, File.basename(r,'.git'))
        if File.exist?(target)
          Zapt.system("cd #{@dir}; git pull")
        else
          Zapt.system("cd #{@dir}; git clone #{r}")
        end
      end
    end

  end
end


