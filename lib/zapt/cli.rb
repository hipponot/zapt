require 'thor'
require 'rubygems/user_interaction'
require 'rubygems/config_file'
require_relative '../zapt'
require_relative 'ui'

# require all commands
root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(root + '/commands/*', &method(:require))

module Zapt
  class CLI < Thor
    include Thor::Actions

    def initialize(*)
      super
      $zapt_no_color = options[:no_color]
      Zapt.set_logger_level options[:verbose] ? 0 : options[:log_level]
      the_shell = (options[:no_color] ? Thor::Shell::Basic.new : shell)
      Zapt.ui = UI::Shell.new(the_shell)
      Zapt.ui.debug! if options[:debug]
      # Let zapt know its running under the cli
      Zapt::Tasks.zapt_cli = true
    end

    check_unknown_options!(:except => [:config, :exec])

    default_task :help
    class_option :arglist,  :type => :array,   :banner => "Arg list", :aliases => "-a"
    class_option :no_color, :type => :boolean, :banner => "Disable colorization in output", :default => false
    class_option :log_level,  :type => :numeric, :banner => "Set the log-level", :aliases => "-l", :default => 1
    class_option :verbose,  :type => :boolean, :banner => "Verbose (max logging)", :aliases => "-v", :lazy_default => true
  end
end
