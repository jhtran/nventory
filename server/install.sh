#!/bin/sh

# Sample installation script for CentOS5

MYSQL_CONFIG_DIR="/usr/bin/mysql_config"
RAILS_VER="2.3.2"

## OPERATING SYSTEM PRE-REQUISITES
# yum install ruby -y
# yum install mysql-server -y
### for rubygems
# yum install -y ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc
### for gems (hpricot & fastthread)
# yum install -y gcc make
### for graphviz gem
# yum install graphviz -y
### for mysql gem
# yum install mysql-devel -y
### for nginx
# yum install -y openssl-devel
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
# ./configure --sbin-path=/sbin/nginx --prefix=/opt/nginx --with-http_ssl_module 
# make && make install

## generate self signed keys & certs for nginx ssl
# openssl genrsa -des3 -out server.key 1024
# openssl req -new -key server.key -out server.csr
# openssl rsa -in server.key -out cert.key
# openssl x509 -req -days 365 -in server.csr -signkey cert.key -out cert.pem

## move your nventory-0.<version>/server directory to /opt/nventory (this is your rails app)
# mv /home/user/nventory-0.83/server /opt/nventory

## copy nginx.conf template overwriting original
# cp /opt/nventory/config/nginx.conf /opt/nginx/conf

## startup nginx
# /sbin/nginx

### install gems
# gem install rails -v $RAILS_VER
# gem install RedCloth -v 3.0.4
# gem install ruby-net-ldap -v 0.0.4
# gem install ruport
# gem install acts_as_reportable
# gem install starling
# gem install fast_xs
# gem install fastercsv
# gem install facter
# ### If hpricot gem install fails, try lower version
# ### Example:  gem install hpricot -v 0.7
# gem install hpricot
# gem install mongrel
# gem install mislav-will_paginate --source http://gems.github.com/ -v 2.3.2
# gem install mongrel -v 1.1.5
# gem install mysql -- --with-mysql-config=$MYSQL_CONFIG_DIR
# gem install ruby-graphviz
# gem install unicorn
# gem install workling
# gem install ruby-debug

# for i in rails RedCloth ruby-net-ldap ruport acts_as_reportable starling fast_xs fastercsv facter hpricot mongrel mislav-will_paginate mongrel mysql ruby-graphviz unicorn workling; do
#  gem list $i |grep $i > /dev/null 2>&1
#  if [ $? != 0 ]; then echo "!! $i not installed." ; fi
# done

## create nventory database
# service mysqld start
# mysql -u root nventory -e 'create database nventory;'

## run nventory's initial db migration to create database schema
# cd /opt/nventory && rake db:migrate

## Startup Rails
# cd /opt/nventory && unicorn_rails --daemonize

