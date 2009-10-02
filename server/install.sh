#!/bin/sh

# Sample installation script for CentOS5

MYSQL_CONFIG_DIR="/usr/bin/mysql_config"
RAILS_VER="2.3.2"

## OPERATING SYSTEM PRE-REQUISITES
# yum install ruby -y
# yum install mysql-server -y
## for rubygems
# yum install -y ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc
## for gems (hpricot & fastthread)
# yum install -y gcc make
## for graphviz gem
# yum install graphviz -y
## for mysql gem
# yum install mysql-devel -y
## for nginx
# yum install -y gcc-c++
# yum install -y zlib-devel
# yum install -y pcre-devel

## goto rubygems.org to download and install rubygems (example below but you want the latest source)
# wget http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz
# tar zxvf rubygems-1.3.5.tgz
# cd rubygems-1.3.5
# ruby setup.rb

## get  nginx installation package (example below but you want the latest source)
# wget http://www.nginx.eu/download/sources/nginx-0.8.9.tar.gz
# tar zxvf nginx-0.8.9.tar.gz
# cd nginx-0.8.9
# ./configure && make && make install

## install gems
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
