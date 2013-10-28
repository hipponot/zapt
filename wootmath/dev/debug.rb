require_relative '../../lib/zapt'


ruby do
  ENV['PATH'] = "#{ENV['PATH']}:#{ENV['HOME']}/kudu/bin:#{ENV['HOME']}/nimbee/build_tools"
  # make this sticky
  profile = "#{ENV['HOME']}/.bash_profile"
  unless File.read(profile) =~ /kudu/
    File.open(profile,'a').puts("export PATH=$PATH:$HOME/kudu/bin:$HOME/nimbee/build_tools")
  end
end

# setup credentials
#
system do
  commands [
            'kudu bootstrap',
            'kudu build -d -n wootcloud',
            'wootcloud bootstrap',
            'wootcloud setup --password=wootmathisawesome', 
           ], working_dir:'~/nimbee', user:Zapt.user
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




