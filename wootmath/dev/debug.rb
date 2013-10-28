require_relative '../../lib/zapt'

ruby do
  ENV['PATH'] = "#{ENV['PATH']}:#{ENV['HOME']}/kudu/bin:#{ENV['HOME']}/nimbee/build_tools"
end

# setup credentials
#
system do
  kudu = '/home/vagrant/kudu/bin/kudu'
  commands [
            "#{kudu} bootstrap"
           ], user:Zapt.user
end
exit(0)

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
           ], user:Zapt.user
end




