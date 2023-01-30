require_relative '../version'

module Zapt
  LOCAL_ZAPT_DIR = File.expand_path(File.join(ENV['HOME'],'dev/zapt'))
  REMOTE_ZAPT_DIR = "zapt"

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

      handle_zapt_has_local_mods
      handle_zapt_remote_is_out_of_date
      handle_zcripts_have_local_mods
      handle_zcripts_local_are_out_of_date

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
        `git diff HEAD --quiet $REF -- $DIR`; local_mods = !$?.success?
        puts BANNER.yellow
        puts wrap("You have local modificatons to #{LOCAL_ZAPT_DIR} Please commit and push before attempting to sync\n", 80)
        puts BANNER.yellow
      }
    end

    def handle_zapt_remote_is_out_of_date
      hosts.each do |host|
        remote_cmd = "cd #{REMOTE_ZAPT_DIR}; git diff origin --quiet"
        rval, out_of_date = !Zapt.system(remote_cmd, host[:user], host[:ip], pem)
        puts rval
        puts out_of_date
      end
    end

    def handle_zcripts_have_local_mods
    end

    def handle_zcripts_local_are_out_of_date
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
      $logger.warn("Updating cluster zapt from github")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; git reset --hard HEAD", host[:user], host[:ip], pem)
      $logger.info("Building and installing zapt on remote node")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; gem build zapt.gemspec; gem install zapt-1.0.1.gem", host[:user], host[:ip], pem)
    end

    def self.exit_on_failure?
      true
    end

  end


end
