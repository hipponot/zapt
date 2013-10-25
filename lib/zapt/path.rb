require 'rbconfig'

module Zapt
  class << self

    def path! value
      value.gsub!('~/', "#{ENV['HOME']}/")
    end

    def path value
      value.gsub('~/', "#{ENV['HOME']}/")
    end

  end
end
