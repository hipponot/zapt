#!/usr/bin/env ruby

require_relative '../../lib/zapt'

#branch = "master"
branch = "sk_10_25"

# latest version of ffmpeg
system do
  commands = [
              'sudo apt-get install python-software-properties',
              'sudo add-apt-repository -y ppa:jon-severinsson/ffmpeg',
              'sudo apt-get update'
             ]
end
package { name 'ffmpeg' }
exit(0)

# apt/brew packages
#
package do
  # default action: :install
  names %w{emacs23 git libxml2-dev mysql-client libmysqlclient-dev ruby-dev libxslt1-dev  libsasl2-dev nginx sox}
end


# setup keys for github access
#
filesystem do
  copy 'id_rsa',     '~/.ssh/.', mode:0600, owner:Zapt.user, group:Zapt.group
  copy 'id_rsa.pub', '~/.ssh/.', mode:0655, owner:Zapt.user, group:Zapt.group
end

# clone repos
#
git do
  repo 'https://github.com/hipponot/kudu.git', working_dir:ENV['HOME']
  repo 'git@github.com:hipponot/nimbee.git', working_dir:ENV['HOME'], branch:branch
end

# put kudu and nimbee/build_tools on the PATH
#
ruby do
  ENV['PATH'] = "#{ENV['PATH']}:#{ENV['HOME']}/kudu/bin:#{ENV['HOME']}/nimbee/build_tools"
  # make this sticky
  profile = "#{ENV['HOME']}/.bash_profile"
  unless File.read(profile) =~ /kudu/
    File.open(profile,'a').puts("export PATH=$PATH:$HOME/kudu/bin:$HOME/nimbee/build_tools")
  end
end

# build kudu
#
system do
  kudu = "#{ENV['HOME']}/kudu/bin/kudu"
  command "#{kudu} bootstrap", working_dir:'~/kudu', user:Zapt.user
  command "#{kudu} build -d -n kudu", working_dir:'~/kudu', user:Zapt.user
end

# setup credentials
#
system do
  commands [
            'kudu build -d -n wootcloud',
            'wootcloud bootstrap',
            'wootcloud setup --password=wootmathisawesome', 
           ], working_dir:'~/nimbee', user:Zapt.user
end

# unicorn/nginx configuration
#
filesystem do
  mkdir [
         '/var/log/unicorn',
         '/tmp/unicorn/pids',
         '/tmp/unicorn/sockets',
         '/etc/nginx/conf.d/upstream',
         '/etc/nginx/conf.d/location'
        ], mode:0755, owner:Zapt.user, group:Zapt.group
  copy 'nginx.conf', '/etc/nginx/nginx.conf', mode:0655
end

# build and deploy APIs
#
system do
  commands [
            'kudu bootstrap',
            'kudu build -d -n woot_cms',
            'kudu build -d -n woot_db',
            'kudu build -d -n woot_storage',
            "kudu deploy -p 3000 -u #{Zapt.user} -e development_copy -n woot_cms",
            "kudu deploy -p 3001 -u #{Zapt.user} -e development_copy -n woot_db",
            "kudu deploy -p 3002 -u #{Zapt.user} -e development_copy -n woot_storage",
           ], working_dir:'~/nimbee', user:Zapt.user
end

# Start apis/nginx
#
system do
  # As user
  commands [
            "/etc/init.d/woot_cms stop",
            "/etc/init.d/woot_cms start",
            "/etc/init.d/woot_db stop",
            "/etc/init.d/woot_db start",
            "/etc/init.d/woot_storage stop",
            "/etc/init.d/woot_storage start",
           ], working_dir:'~/nimbee', user:Zapt.user
  # As root
  commands [
            "/etc/init.d/nginx restart",
           ]
end



