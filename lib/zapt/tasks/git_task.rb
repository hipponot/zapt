require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative 'common/dir'

module Zapt

  class GitTask < Task

    def initialize args
    end

    def repos value, user:Zapt.user, working_dir:ENV['HOME']
       value.each { |r| update_or_clone(r, user, Zapt.path(dir)) }
    end

    def repo value, user:Zapt.user, working_dir:ENV['HOME']
      update_or_clone(value, user, dir)
    end

    private

    def update_or_clone repo, user, working_dir
      target = File.join(working_dir, File.basename(repo,'.git'))
      if File.exist?(target)
        Zapt.system("cd #{target}; GIT_SSH=#{Zapt.bin}/gitssh.sh git pull")
      else
        Zapt.system("cd #{working_dir}; GIT_SSH=\"ssh -i #{ENV['HOME']}/.ssh/id_rsa.pub\" git clone #{repo}")
      end
    end


  end
end
