require 'fileutils'
require 'erubis'

require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative '../path'

module Zapt
  class FilesystemTask < Task

    def initialize args
      super
    end

    def erb source, target, owner:nil, group:nil, mode:nil
      eruby = Erubis::Eruby.new(IO.read(source))
      IO.write(target, eruby.result(binding()))
      file_operation(nil, target, nil, owner, group, mode)
    end

    def copy source, target, owner:nil, group:nil, mode:nil
      file_operation(:copy, target, source, owner, group, mode)
    end

    def mkdir target, owner:nil, group:nil, mode:nil
      mkdir_op = lambda { |path| file_operation(:mkdir, path, nil, owner, group, mode) }
      target.is_a?(Array) ? target.each(&mkdir_op) : mkdir_op[target]
    end

    def file_operation op, target, source, owner, group, mode
      # condition paths 
      [source, target].compact.map{ |p| Zapt.path!(p) }
      case op
      when :copy
        target = File.join(target, File.basename(source)) if File.directory?(target)
        FileUtils.cp(source, target)
      when :mkdir
        FileUtils.mkdir_p(target)
      end
      FileUtils.chown(owner, nil, target) if owner
      FileUtils.chown(nil, group, target) if group
      FileUtils.chmod(mode, target) if mode
    end

  end
end


