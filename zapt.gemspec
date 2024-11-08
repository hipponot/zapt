# frozen_string_literal: true

require_relative "lib/zapt/version"

Gem::Specification.new do |spec|
  spec.name = "zapt"
  spec.version = Zapt::VERSION
  spec.authors = ["Sean Kelly"]
  spec.email = ["skelly@saga.org"]
  spec.license = "MIT"

  spec.summary = "cluster deploy remoting"
  spec.required_ruby_version = ">= 3.0.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "bin"
  spec.executables = ['zapt']
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.2.2"
  spec.add_dependency "mongo", "~> 1.12.5"
  spec.add_dependency "bson_ext", "~> 1.12.5"
  spec.add_dependency "logger", "~> 1.6.0"
  spec.add_dependency "colored", "~> 1.2"
  spec.add_dependency "erubis", "~> 2.7"
  spec.add_dependency "facter", "~> 4.10"
  spec.add_dependency "rvm", "~> 1.11"
end
