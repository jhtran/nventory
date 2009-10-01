#!/bin/sh

MYSQL_CONFIG_DIR="/usr/bin/mysql_config"
RAILS_VER="2.3.2"

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
