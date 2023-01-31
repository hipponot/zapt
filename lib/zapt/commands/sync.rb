require_relative '../version'

module Zapt
  LOCAL_ZAPT_DIR = File.expand_path(File.join(ENV['HOME'],'dev/zapt'))
  REMOTE_ZAPT_DIR = "zapt"
  LOCAL_ZCRIPTS_DIR = File.expand_path(File.join(ENV['HOME'],'dev/vega/zcripts'))
  REMOTE_ZCRIPTS_DIR = "zcripts"

  BANNER = "#"*80

  class CLI < Thor
    attr_reader :cluster_conf
    attr_reader :hosts, :pem

    method_option :cluster, :aliases => "-c", :type=>:string, :required=>true, :desc => "cluster name or path to cluster def yaml"
    method_option :yes, :aliases => "-y", :type=>:boolean, :required=>false, :desc => "yes to all prompts"
    desc "sync", "print version"
    def sync

      cluster = options[:cluster]
      unless File.exist? cluster
        cluster = File.join(ENV['HOME'], 'dev/vega/zcripts/common/cluster_defs/', "#{cluster}.yaml")
      end

      $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster)
      @cluster_conf = YAML::load(IO.read(cluster))
      @pem = "#{ENV['HOME']}/credentials/#{cluster_conf[:key]}.pem"
      @hosts = []
      cluster_conf[:nodes].each do |node|
        ip = Zapt.is_aws_vpn? ? node[:internal_ip] : node[:public_ip]
        user = node[:user]
        hosts << { ip:ip, user:user }
      end

      # sync zapt
      # ToDo - check for unpushed CS
      return if handle_zapt_has_local_mods # abort if local mods or unpushed changes
      handle_local_zapt_is_out_of_date
      handle_remote_zapt_is_out_of_date

      # sync zcripts
      # ToDo - check for unpushed CS
      return if handle_zcripts_have_local_mods # abort if local mods or unpushed changes
      handle_remote_zcripts_are_out_of_date

    end
      # $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster)
      # local_build = "git pull; gem build zapt.gemspec; gem install zapt-1.0.1.gem"
      # $logger.warn("Running: #{local_build}")
      # rval, = system(local_build)

      # @cluster_conf = YAML::load(IO.read(cluster))
      # hosts = []
      # cluster_conf[:nodes].each do |node|      #   unless File.exist? cluster
      #     cluster = File.join(ENV['HOME'], 'dev/vega/zcripts/common/cluster_defs/', "#{cluster}.yaml")
      #   end

      #   ip = Zapt.is_aws_vpn? ? node[:internal_ip] : node[:public_ip]
      #   user = node[:user]
      #   hosts << { ip:ip, user:user }
      # end
      #     hub
      #     ans = no_prompt ? true : (yes? "Local zapt version differs from (github) origin, do you want to continue with sync?")
      #     unless ans
      #       $logger.info("You can rerun this command after pulling remote changes or pushing local changes")
      #       return
      #     end
      #   end

      #   local_hash = `find #{LOCAL_ZAPT_DIR}/lib -type f -name '*.rb' | sort -d | xargs cat | md5sum`.split(/\s+/).first
      #   # either the full path or just the name
      #   cluster = options[:cluster]
      #   unless File.exist? cluster
      #     cluster = File.join(ENV['HOME'], 'dev/vega/zcripts/common/cluster_defs/', "#{cluster}.yaml")
      #   end
      #   $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster)
      #   local_build = "git pull; gem build zapt.gemspec; gem install zapt-1.0.1.gem"
      #   $logger.warn("Running: #{local_build}")
      #   rval, = system(local_build)

      #   @cluster_conf = YAML::load(IO.read(cluster))
      #   hosts = []
      #   cluster_conf[:nodes].each do |node|
      #     ip = Zapt.is_aws_vpn? ? node[:internal_ip] : node[:public_ip]
      #     user = node[:user]
      #     hosts << { ip:ip, user:user }
      #   end

      #   # pem from top level cluster config
      #   remote_hash_cmd = "find #{REMOTE_ZAPT_DIR}/lib -type f -name '*.rb' | sort -d | xargs cat | md5sum"



      #   hosts.each_with_index do |host|
      #     rval, = Zapt.system(remote_hash_cmd, host[:user], host[:ip], pem)
      #     remote_hash = rval.split(/\s+/).first
      #     if local_diff_from_
      #       github
      #       unless (local_hash == remote_hash)
      #         $logger.warn("local and #{cluster_conf[:name]} cluster versions of zapt source differ")
      #         ans = no_prompt ? true : (yes? "Do you want to sync zapt to cluster #{cluster_conf[:name]} (Y/N)")
      #         return unless ans
      #         update_cluster_zapt_from_local(host, pem)
      #       end
      #     else
      #       $logger.warn("local and github versions of zapt are the same")
      #       update_cluster_zapt_from_github(host, pem)
      #     end
      #   end
      # }
      # $logger.warn("Running rsync_zcripts task")
      # Dir.chdir(File.join(ENV['HOME'], 'dev/vega/zcripts/cluster')) {
      #   cmd = %Q{zapt runtask -r rsync_zcripts -a "{cluster_name:'#{cluster_conf[:name]}'}"}
      #   system(cmd)
      # }

    private


    def wrap(s, width=78)
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
    end


    def handle_zapt_has_local_mods
      Dir.chdir(LOCAL_ZAPT_DIR) {
        `git diff HEAD --quiet $REF -- $DIR .`; local_mods = !$?.success?
        puts BANNER.yellow
        puts wrap("Checking local zapt for modifications:\n", 80)
        if local_mods
          puts wrap("You have local modificatons to #{LOCAL_ZAPT_DIR} Please commit and push before attempting to sync\n", 80)
        else
          puts wrap("Local zapt has no local modifications")
        end
        if !local_mods
          unpushed_commits = !`git cherry -v`.empty?
          if unpushed_commits
            puts wrap("You have unpushed commits to #{LOCAL_ZAPT_DIR}. Please push before attempting to sync\n", 80)
          else
            puts wrap("Local zapt has no unpushed commits")
          end
        end
        puts BANNER.yellow
        return local_mods || unpushed_commits
      }
    end

    def handle_local_zapt_is_out_of_date
      puts BANNER.yellow
      puts wrap("Checking local zapt is up to date:\n", 80)
        local_cmd = "cd #{LOCAL_ZAPT_DIR}; git fetch; git diff origin --quiet"
        `#{local_cmd}`; up_to_date = $?.success?
        if up_to_date
          puts wrap("Local zapt is up to date with origin")
        else
          puts wrap("Local_zapt needs an update")
          update_local_zapt_from_github()
        end
      puts BANNER.yellow
    end

    def handle_remote_zapt_is_out_of_date
      puts BANNER.yellow
      puts wrap("Checking Remote Zapt:\n", 80)
      hosts.each do |host|
        remote_cmd = "cd #{REMOTE_ZAPT_DIR}; git fetch; git diff origin --quiet"
        rval, up_to_date = Zapt.system(remote_cmd, host[:user], host[:ip], pem, true, true) # quiet and ignore_failure
        if up_to_date
          puts wrap("Remote zapt is up to date with origin")
        else
          puts wrap("Remote zapt needs an update")
          update_cluster_zapt_from_github(host, pem)
        end
      end
      puts BANNER.yellow
    end

    def handle_zcripts_have_local_mods
      Dir.chdir(LOCAL_ZCRIPTS_DIR) {
        `git diff HEAD --quiet $REF -- $DIR .`; local_mods = !$?.success?
        puts BANNER.yellow
        puts wrap("Checking local zcripts:\n", 80)
        if local_mods
          puts wrap("You have local modificatons to #{LOCAL_ZAPT_DIR}. Please commit and push before attempting to sync\n", 80)
        else
          puts wrap("Local zcripts have no local modifications")
        end
        if !local_mods
          unpushed_commits = !`git cherry -v`.empty?
          if unpushed_commits
            puts wrap("You have unpushed commits to #{LOCAL_ZCRIPTS_DIR}. Please push before attempting to sync\n", 80)
          else
            puts wrap("Local zcripts have no unpushed commits")
          end
        end
        puts BANNER.yellow
        return local_mods || unpushed_commits
      }
    end

    def handle_remote_zcripts_are_out_of_date
    end

    def update_cluster_zapt_from_local(host, pem)
      user, ip = host.values_at(:user, :ip)
      $logger.warn("Updating cluster zapt from local")
      cmd = "rsync -av -e \"ssh -i #{pem} -l #{user}\"   #{LOCAL_ZAPT_DIR}/lib #{user}@#{ip}:#{REMOTE_ZAPT_DIR}"
      $logger.info("Running: #{cmd}")
      system(cmd)
      $logger.warn("Building and installing zapt on remote node")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; gem build zapt.gemspec; gem install zapt-1.0.1.gem", host[:user], host[:ip], pem)
    end

    def update_cluster_zapt_from_github(host, pem)
      puts wrap("Updating zapt from github on host #{host}")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; git reset --hard HEAD; git pull", host[:user], host[:ip], pem, true)
      puts wrap("Building and installing zapt on remote node")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; gem build zapt.gemspec; gem install zapt-1.0.1.gem", host[:user], host[:ip], pem, true)
    end

    def update_local_zapt_from_github()
      puts wrap("Updating local zapt from github")
      status = system("git reset --hard HEAD; git pull")
      abort("Something went wrong with pulling local zapt") unless status
      puts wrap("Building and installing local zapt")
      status = system("gem build zapt.gemspec; gem install zapt-1.0.1.gem")
      abort("Something went wrong building zapt locally") unless status
    end

    def self.exit_on_failure?
      true
    end

  end


end
