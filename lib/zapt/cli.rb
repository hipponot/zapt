require 'thor'
require 'rubygems/user_interaction'
require 'rubygems/config_file'
require_relative '../zapt'
# require all commands
root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(root + '/commands/*', &method(:require))

module Zapt
  class CLI < Thor
    include Thor::Actions

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      Zapt.ui = UI::Shell.new(the_shell)
      Zapt.ui.debug! if options["debug"]
      # Let zapt know its running under the cli
      Zapt::Tasks.zapt_cli = true
    end

    check_unknown_options!(:except => [:config, :exec])

    default_task :help
    class_option "no-color", :type => :boolean, :banner => "Disable colorization in output"
    class_option "verbose",  :type => :boolean, :banner => "Enable verbose output mode", :aliases => "-V"

  end
end
