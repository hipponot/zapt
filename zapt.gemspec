# frozen_string_literal: true

require_relative "lib/zapt/version"

Gem::Specification.new do |spec|
  spec.name = "zapt"
  spec.version = Zapt::VERSION
  spec.authors = ["Sean Kelly"]
  spec.email = ["skelly@sagaeducation.org"]

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

  spec.add_dependency "thor", "1.2.2"
  spec.add_dependency "colored"
  spec.add_dependency "erubis"
  spec.add_dependency "logger"
  spec.add_dependency "facter"
  spec.add_dependency "rvm"

end
