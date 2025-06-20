#!/usr/bin/env ruby
require 'bundler'

begin
  # check bundle
  `bundle check`; status=$?.success?
  if(!status)
    # If gems or Gemfile are missing, run bundle install
    puts "Running `bundle install` to install missing gems..."
    system('bundle install') || abort("Failed to run `bundle install`")
  end
  # load bundle
  require 'bundler/setup'
  Bundler.require(:default)
end

# Your script logic here
#puts "Bundler is happy.. Running the script..."
