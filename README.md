zapt
====

## Introduction
Are you a ruby fan that can't stand CHEF? Do you need to configure some servers? or run some
complex workflow? Zapt is a task based workflow DSL designed to keep
it simple and stay out of your way.

## Getting Started
Basic idea is require 'zapt' and writes some tasks.  It will have task
dependencies, remoting, parallelization and idempotence but for now
it just runs stuff :immediately in the order expressed.

```ruby
require 'zapt'
# install some packages
package do
  names %w{emacs23 git libxml2-dev mysql-client}
end

# do some filesystem stuff
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

# clone a repo
git do
  repo 'https://github.com/hipponot/kudu.git', working_dir:ENV['HOME']
end

# task in plain old ruby
ruby do
  puts 'yoda'
end

# plain old ruby (no task)
puts 'luke'

```
You don't need a CLI or a server or databags or cookbooks or..., just
a directory with your stuff and a bit of ruby that looks like the
above. To exectue just run the ruby.
```
> rvmsudo ./tasks.rb
```
