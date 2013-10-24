module Zapt
  module Common
    module Dir
      attr_accessor :dir
      def dir value
        @dir = value.gsub('~/', "#{ENV['HOME']}/") 
      end
    end
  end
end


