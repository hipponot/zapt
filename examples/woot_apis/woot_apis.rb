require_relative '../../lib/zapt'

package do
  names %w{emacs23 git libxml2-dev mysql-client libmysqlclient-dev ruby-dev libxslt1-dev  libsasl2-dev}
end

filesystem do
  copy 'id_rsa',     '~/.ssh/.', :mode=>0600
  copy 'id_rsa.pub', '~/.ssh/.', :mode=>0655
end

git do
  repos [
         'https://github.com/hipponot/kudu.git', 
         'git@github.com:hipponot/nimbee.git'
        ], working_dir:ENV['HOME']
end

ruby do
  # put kudu and nimbee/build_tools on the PATH
  ENV['PATH'] = "#{ENV['PATH']}:#{ENV['HOME']}/kudu/bin:#{ENV['HOME']}/nimbee/build_tools"
  # make this sticky
  profile = "#{ENV['HOME']}/.bash_profile"
  unless File.read(profile) =~ /kudu/
    File.open(profile,'a').puts("export PATH=$PATH:$HOME/kudu/bin:$HOME/nimbee/build_tools")
  end
end

system :kudu_build do
  commands [
            'kudu bootstrap',
            'kudu build -d -n woot_cms',
            'kudu build -d -n woot_db',
            'kudu build -d -n woot_storage'
           ], working_dir:'~/nimbee'
end

filesystem do
  mkdir [
         '/var/log/unicorn',
         '/tmp/unicorn/pids',
         '/tmp/unicorn/sockets',
         '/etc/nginx/conf.d/upstream',
         '/etc/nginx/conf.d/location'
        ], mode:0755, owner:Zapt.user, group:Zapt.group
end

