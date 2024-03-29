require_relative '../version'

module Zapt
  LOCAL_ZAPT_DIR = is_ec2_build_server? ? File.expand_path(File.join(ENV['HOME'],'zapt')) : File.expand_path(File.join(ENV['HOME'],'dev/zapt'))
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
        ip = Zapt.is_aws_vpn? || Zapt.is_ec2_build_server? ? node[:internal_ip] : node[:public_ip]
        user = node[:user]
        hosts << { ip:ip, user:user }
      end

      puts BANNER.yellow
      # sync zapt
      # abort('Aborting zapt sync') if handle_zapt_has_local_mods # abort if local mods or unpushed changes
      #handle_local_zapt_is_out_of_date

      # ToDo: remote zapt should be in the same detached head state
      #handle_remote_zapt_is_out_of_date

      # sync zcripts
      # return if handle_zcripts_have_local_mods # abort if local mods or unpushed changes
      #handle_local_zcripts_are_out_of_date unless is_detached_head?
      #handle_remote_zcripts_are_out_of_date

    end

    private

    def wrap(s, width=78)
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
    end

    def is_detached_head?
      Dir.chdir(LOCAL_ZCRIPTS_DIR) {
        `git branch | grep '*'`; rval = $?.success?
        return rval
      }
    end

    def handle_zapt_has_local_mods
      Dir.chdir(LOCAL_ZAPT_DIR) {
        `git diff HEAD --quiet $REF -- $DIR .`; local_mods = !$?.success?
        puts wrap("Checking local zapt:\n", 80)
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
      Dir.chdir(LOCAL_ZAPT_DIR) {
        puts wrap("Checking local zapt:\n", 80)
          local_cmd = "cd #{LOCAL_ZAPT_DIR}; git fetch; git diff origin --quiet"
          `#{local_cmd}`; up_to_date = $?.success?
          if up_to_date
            puts wrap("Local zapt is up to date with origin")
          else
            puts wrap("Local zapt needs an update")
            update_local_zapt_from_github()
          end
        puts BANNER.yellow
      }
    end

    def handle_local_zcripts_are_out_of_date
      puts wrap("Checking local zcripts:\n", 80)
        local_cmd = "cd #{LOCAL_ZCRIPTS_DIR}; git fetch; git diff --quiet origin ." # note the . -- don't want the whole repo just zcripts
        `#{local_cmd}`; up_to_date = $?.success?
        if up_to_date
          puts wrap("Local zcripts are up to date with origin")
        else
          puts wrap("Local zcripts needs an update")
          update_local_zcripts_from_github()
        end
      puts BANNER.yellow
    end

    def handle_remote_zapt_is_out_of_date
      puts wrap("Checking remote zapt:\n", 80)
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
        puts wrap("Checking local zcripts:\n", 80)
        if local_mods
          puts wrap("You have local modificatons to #{LOCAL_ZCRIPTS_DIR}. Please commit and push before attempting to sync\n", 80)
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
      puts wrap("Checking if remote zcripts need rsync:\n", 80)
      local_hash = `find #{LOCAL_ZCRIPTS_DIR} -type f | grep -v cluster_defs | sort -d | xargs cat | md5sum`.chomp
      hosts.each do |host|
        cmd = %Q{rsync  --out-format="%f" -n -arc -e "ssh -i #{pem} -l #{host[:user]}" #{LOCAL_ZCRIPTS_DIR} #{host[:user]}@#{host[:ip]}:. --exclude "common/cluster_defs/*"}
        rval = `#{cmd}`
        if rval.empty?
          puts wrap("Remote zcripts are up to date")
        else
          puts wrap("Remote zcripts need rsynced")
          cmd = %Q{cd #{ENV['HOME']}/dev/vega/zcripts/cluster; zapt runtask -r rsync_zcripts -a "{cluster_name:'#{cluster_conf[:name]}'}"}
          system(cmd)
        end
      end
      puts BANNER.yellow
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

    def update_local_zcripts_from_github()
      puts wrap("Updating local zcripts from github")
      status = system("git checkout -- .; git pull")
      abort("Something went wrong with pulling local zcripts") unless status
    end

    def self.exit_on_failure?
      true
    end

  end


end
