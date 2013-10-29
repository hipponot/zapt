zapt
====

## Introduction
Love ruby ?, hate CHEF ? need to configure some servers ? Zapt is a
task based provisioning made easy.

## Getting Started

Basic idea is require 'zapt' and writes some tasks.  It will have task
dependencies, remoting, parallelization and idempotence but for now
its just runs stuff :immediately in the order expressed.

```ruby
require_relative 'zapt'
# install some packages
package do
  names %w{emacs23 git libxml2-dev mysql-client}
end

# do some filesystem stuff
filesystem do
  copy 'id_rsa',     '~/.ssh/.', mode:0600, owner:Zapt.user, group:Zapt.group
  copy 'id_rsa.pub', '~/.ssh/.', mode:0655, owner:Zapt.user, group:Zapt.group
end

# clone a repo
git do
  repo 'https://github.com/hipponot/kudu.git', working_dir:ENV['HOME']
end

```

You don't need a CLI or a server or databags or cookbooks or..., just a directory
with your stuff and a bit of ruby that looks like the above.
```
> rvmsudo task.rb
```
