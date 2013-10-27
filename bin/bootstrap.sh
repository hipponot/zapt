#!/usr/bin/env sh
#sudo apt-get -qq install curl
\curl -L https://get.rvm.io | bash -s stable --ruby
gem install popen4 colored
echo "export rvmsudo_secure_path=1" >> $HOME/.bash_profile