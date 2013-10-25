require_relative '../../path'
module Zapt
  module Common
    module Dir
      attr_accessor :dir
      def dir value
        @dir = Zapt.path(value) 
      end
    end
  end
end


