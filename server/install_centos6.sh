#!/bin/sh

BASE_DIR='./'
NVENTORY_DIR='/opt/nventory'
NGINX_CONFD='/etc/nginx'

# Sample installation script for CentOS6

MYSQL_CONFIG_FILE="/usr/bin/mysql_config"
RAILS_VER="2.3.9"
RUBY_VER="1.8.7"
RUBYGEMS_VER="1.5.3"

## install epel repo
sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/6/i386/epel-release-6-5.noarch.rpm

sudo yum groupinstall "Development Tools" -y
sudo yum install mysql-server -y
sudo service mysqld start


### OPERATING SYSTEM PRE-REQUISITES
sudo yum install -y ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc
sudo yum install -y rubygems
sudo gem update --system && sudo gem update --system $RUBYGEMS_VER
sudo yum install -y graphviz 
sudo yum install -y nginx

### DEFAULT copy fake certs and keys for SSL
echo "*** USING FAKE SSL KEYS AND CERTS ***"
if [ ! -d $NGINX_CONFD ]; then
  sudo mkdir -p $NGINX_CONFD
fi
sudo cp $BASE_DIR/fakecerts/* $NGINX_CONFD

### uncomment the following, if you want to generate self signed keys & certs for nginx ssl
#sudo openssl genrsa -des3 -out $NGINX_CONFD/server.key 1024
#sudo openssl req -new -key $NGINX_CONFD/server.key -out $NGINX_CONFD/server.csr
#sudo openssl rsa -in $NGINX_CONFD/server.key -out $NGINX_CONFD/cert.key
#sudo openssl x509 -req -days 365 -in $NGINX_CONFD/server.csr -signkey $NGINX_CONFD/cert.key -out $NGINX_CONFD/cert.pem

### INSTALL NVENTORY ###
if [ ! -d $NVENTORY_DIR ]; then
  sudo mkdir -p $NVENTORY_DIR
fi
sudo cp -r $BASE_DIR $NVENTORY_DIR
sudo cp $NVENTORY_DIR/config/nginx.conf $NGINX_CONFD
user=`whoami`
sudo chown -R $user $NVENTORY_DIR

### startup nginx
sudo service nginx start

## RUBYGEMS ##
sudo gem install rails -v $RAILS_VER
sudo gem install RedCloth -v 4.2.2
sudo gem install ruby-net-ldap -v 0.0.4
sudo gem install hoe -v 2.3.2
sudo gem install ruport -v 1.6.1
sudo gem install acts_as_reportable -v 1.1.1
sudo gem install starling -v 0.9.8
sudo gem install fast_xs -v 0.7.3
sudo gem install fastercsv -v 1.2.3
sudo gem install facter -v 1.5.6
sudo gem install hpricot -v 0.8.1
sudo gem install mislav-will_paginate -v 2.3.8
sudo gem install ruby-mysql -v 2.9.4
sudo gem install ruby-graphviz -v 0.9.0
sudo gem install unicorn -v 0.91.0
sudo gem install workling -v 0.4.9.9
sudo gem install ruby-debug -v 0.10.3
sudo gem install is_graffitiable -v 0.1.4

for i in rails RedCloth ruby-net-ldap ruport acts_as_reportable starling fast_xs fastercsv facter hpricot mislav-will_paginate ruby-mysql ruby-graphviz unicorn workling is_graffitiable; do
  gem list $i |grep $i > /dev/null 2>&1
  if [ $? != 0 ]; then echo "!! $i not installed." ; fi
done

## create nventory database
mysql -u root -e 'create database nventory;'

## run nventory's initial db migration to create database schema
cd $NVENTORY_DIR && rake db:migrate

## Startup Rails
unicorn_rails --daemonize
if [ $? == 0 ]; then
  echo "*** UNICORN STARTED ###"
  echo "*** NVENTORY SUCCESSFULLY INSTALLED ***"
fi
