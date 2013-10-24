require_relative '../lib/zapt'

# put kudu and nimbee/build_tools on the PATH
ruby do
  profile = "#{ENV['HOME']}/.bash_profile"
  unless File.read(profile) =~ /kudu/
    File.open(profile,'a').puts("export PATH=$PATH:$HOME/kudu/bin:$HOME/nimbee/build_tools")
  end
end

exit(0)
file do
  copy '~/.ssh/id_rsa',     '~/tmp', :mode=>0600
  copy '~/.ssh/id_rsa.pub', '~/tmp', :mode=>0655
end

git do
  repo 'https://github.com/hipponot/kudu.git'
  dir "#{ENV['HOME']}/tmp"
end

system do
  commands ['ls -ltr', 'echo yoda']
end

package do
  names %w{memcached nginx}
end

gem do
  names %w{popen4 json}
end

