#!/bin/sh

# Sample installation script for CentOS5

MYSQL_CONFIG_DIR="/usr/bin/mysql_config"
RAILS_VER="2.3.2"

## OPERATING SYSTEM PRE-REQUISITES
# yum install mysql-server -y
# yum install mysql-devel -y
# yum install graphviz -y
# yum install ruby -y
# yum install -y ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc

# goto rubygems.org to download and install rubygems

gem install rails -v $RAILS_VER
gem install RedCloth -v 3.0.4
gem install ruby-net-ldap -v 0.0.4
gem install ruport
gem install acts_as_reportable
gem install starling
gem install fast_xs
gem install fastercsv
gem install facter
## If hpricot gem install fails, try lower version
## Example:  gem install hpricot -v 0.7
gem install hpricot
gem install mongrel
gem install mislav-will_paginate --source http://gems.github.com/ -v 2.3.2
gem install mongrel -v 1.1.5
gem install mysql -- --with-mysql-config=$MYSQL_CONFIG_DIR
gem install ruby-graphviz
