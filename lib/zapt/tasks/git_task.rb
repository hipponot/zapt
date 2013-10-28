require_relative '../task'
require_relative '../os'
require_relative '../system'
require_relative 'common/dir'

module Zapt

  class GitTask < Task

    def initialize args
      @gitssh = "#{Zapt.bin}/gitssh.sh"
    end

    def repos value, user:Zapt.user, working_dir:ENV['HOME'], branch:nil
       value.each { |r| update_or_clone(r, user, Zapt.path(working_dir), branch) }
    end

    def repo value, user:Zapt.user, working_dir:ENV['HOME'], branch:nil
      update_or_clone(value, user, working_dir, branch)
    end

    private

    def update_or_clone repo, user, working_dir, branch
      target = File.join(working_dir, File.basename(repo,'.git'))
      switch_to_branch = lambda { Zapt.system("cd #{target}; git checkout #{branch}") unless branch.nil?} 
      if File.exist?(target)
        # before pull
        switch_to_branch[]
        Zapt.system("cd #{target}; GIT_SSH=#{@gitssh} git pull", user)
      else
        Zapt.system("cd #{working_dir}; GIT_SSH=#{@gitssh} git clone #{repo}", user)
        # after clone
        switch_to_branch[]
      end
    end

  end
end
