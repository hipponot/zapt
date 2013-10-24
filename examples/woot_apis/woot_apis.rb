require_relative '../lib/zapt'

package do
  names %w{emacs23 git}
end

file do
  copy 'ida_rsa',     '~/.ssh/.', mode=>0600
  copy 'ida_rsa.pub', '~/.ssh/.', mode=>0655
end

git do
  repos ['https://github.com/hipponot/kudu.git', 'https://github.com/hipponot/nimbee.git']
  dir ENV['HOME']
end

system do
  commands [
            'kudu/bin/kudu bootstrap',
            'cd ~/nimbee ~/kudu/bin/kudu build -d woot_cms',
            'cd ~/nimbee ~/kudu/bin/kudu build -d woot_db',
            'cd ~/nimbee ~/kudu/bin/kudu build -d woot_storage'
           ]
end
# gem do
#   names %w{popen4 json}
# end

