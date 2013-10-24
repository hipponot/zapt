#!/usr/bin/env sh
sudo apt-get -qq install curl
\curl -L https://get.rvm.io | bash -s stable --ruby
source ~/.rvm/scripts/rvm
gem install popen4 colored