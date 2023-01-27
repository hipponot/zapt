require_relative '../version'

module Zapt
  LOCAL_ZAPT_DIR = File.expand_path(File.join(ENV['HOME'],'dev/zapt'))
  REMOTE_ZAPT_DIR = "zapt"

  class CLI < Thor
    attr_reader :cluster_conf
    method_option :cluster, :aliases => "-c", :type=>:string, :required=>true, :desc => "cluster name or path to cluster def yaml"
    method_option :yes, :aliases => "-y", :type=>:boolean, :required=>false, :desc => "yes to all prompts"
    desc "sync", "print version"
    def sync
      Dir.chdir(LOCAL_ZAPT_DIR) {
        no_prompt = options[:yes]
        `git diff origin --quiet`; local_diff_from_github = $?
        if local_diff_from_github
          ans = no_prompt ? true : (yes? "Local zapt version differs from (github) origin, do you want to continue with sync?")
          unless ans
            $logger.info("You can rerun this command after pulling remote changes or pushing local changes")
            return
          end
        end

        local_hash = `find #{LOCAL_ZAPT_DIR}/lib -type f -name '*.rb' | sort -d | xargs cat | md5sum`.split(/\s+/).first
        # either the full path or just the name
        cluster = options[:cluster]
        unless File.exist? cluster
          cluster = File.join(ENV['HOME'], 'dev/vega/zcripts/common/cluster_defs/', "#{cluster}.yaml")
        end
        $logger.error("Can't find cluster definition #{cluster}") and exit(1) unless File.exist?(cluster)
        local_build = "git pull; gem build zapt.gemspec; gem install zapt-1.0.1.gem"
        $logger.warn("Running: #{local_build}")
        rval, = system(local_build)

        @cluster_conf = YAML::load(IO.read(cluster))
        hosts = []
        cluster_conf[:nodes].each do |node|
          ip = Zapt.is_aws_vpn? ? node[:internal_ip] : node[:public_ip]
          user = node[:user]
          hosts << { ip:ip, user:user }
        end

        # pem from top level cluster config
        remote_hash_cmd = "find #{REMOTE_ZAPT_DIR}/lib -type f -name '*.rb' | sort -d | xargs cat | md5sum"
        pem = "#{ENV['HOME']}/credentials/#{cluster_conf[:key]}.pem"

        hosts.each_with_index do |host|
          rval, = Zapt.system(remote_hash_cmd, host[:user], host[:ip], pem)
          remote_hash = rval.split(/\s+/).first
          unless (local_hash == remote_hash)
            $logger.warn("local and #{cluster_conf[:name]} cluster versions of zapt source differ")
            ans = no_prompt ? true : (yes? "Do you want to sync zapt to cluster #{cluster_conf[:name]} (Y/N)")
            return unless ans
            if ans
              if local_diff_from_github
                update_cluster_zapt_from_local(host, pem)
              else
                update_cluster_zapt_from_github(host, pem)
              end
            end
          else
            $logger.warn("local and #{cluster_conf[:name]} cluster versions of zapt source match")
          end
        end
      }
      $logger.warn("Running rsync_zcripts task")
      Dir.chdir(File.join(ENV['HOME'], 'dev/vega/zcripts/cluster')) {
        cmd = %Q{zapt runtask -r rsync_zcripts -a "{cluster_name:'#{cluster_conf[:name]}'}"}
        system(cmd)
      }


    end

    private

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
      $logger.info("Updating cluster zapt from github")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; git reset --hard HEAD", host[:user], host[:ip], pem)
      $logger.info("Building and installing zapt on remote node")
      rval, = Zapt.system("cd #{REMOTE_ZAPT_DIR}; gem build zapt.gemspec; gem install zapt-1.0.1.gem", host[:user], host[:ip], pem)
    end

    def self.exit_on_failure?
      true
    end

  end

end
