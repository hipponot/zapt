require_relative '../lib/zapt'

filesystem do
  @value = "hello world"
  erb 'example.txt.erb', 'example.txt'
end
exit(0)

filesystem do
  mkdir [
         '/tmp/foobar'
        ], mode:0755, owner:Zapt.user, group:Zapt.group
end

exit(0)

git do
  repos ['https://github.com/hipponot/kudu.git', 'git@github.com:hipponot/nimbee.git'], dir:ENV['HOME']
end



git do
  repos ['https://github.com/hipponot/kudu.git', 'git@github.com:hipponot/nimbee.git'], dir:"#{ENV['HOME']}/tmp"
end

exit(0)

filesystem do
  mkdir ['~/tmp/foo', '~/tmp/blah'], :mode=>777
  copy '~/.ssh/id_rsa',     '~/tmp', :mode=>0600
  copy '~/.ssh/id_rsa.pub', '~/tmp', :mode=>0655
end


# put kudu and nimbee/build_tools on the PATH
ruby do
  profile = "#{ENV['HOME']}/.bash_profile"
  unless File.read(profile) =~ /kudu/
    File.open(profile,'a').puts("export PATH=$PATH:$HOME/kudu/bin:$HOME/nimbee/build_tools")
  end
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

