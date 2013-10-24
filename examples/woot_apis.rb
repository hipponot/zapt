require_relative '../lib/zapt'

package do
  names %w{emacs23}
end

git do
  repo 'https://github.com/hipponot/kudu.git'
  dir ENV['HOME']
end


# gem do
#   names %w{popen4 json}
# end

