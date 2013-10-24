require_relative '../lib/zapt'

system do
  command '\curl -L https://get.rvm.io | bash -s stable'
end

package do
  names %w{memcached nginx}
end

gem do
  names %w{popen4 json}
end

