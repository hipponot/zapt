require 'fileutils'

require_relative '../task'
require_relative '../os'
require_relative '../system'

module Zapt
  class FileTask < Task

    attr_accessor :operations

    def initialize
      @operations ||= []
    end

    def copy source, target, options={}
      [source, target].each { |p| p.gsub!('~/', "#{ENV['HOME']}/") }
      target = File.join(target, File.basename(source)) if File.directory?(target)
      operations << {:action=>:copy, :source=>source, :target=>target, :options=>options}
    end

    def run
      operations.each do |o|
        case o[:action]
        when :copy
          FileUtils.cp(o[:source], o[:target])
          options = o[:options]
          FileUtils.chown(options[:owner], nil, o[:target]) if options.has_key?(:owner) 
          FileUtils.chown(nil, options[:group], o[:target]) if options.has_key?(:group) 
          FileUtils.chmod(options[:mode], o[:target]) if options.has_key?(:mode)
        end
      end
    end

  end
end


