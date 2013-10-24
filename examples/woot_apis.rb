require_relative '../lib/zapt'

git do
  repo 'https://github.com/hipponot/kudu.git'
  dir ENV['HOME']
end

# package do
#   names %w{memcached nginx}
# end

# gem do
#   names %w{popen4 json}
# end

