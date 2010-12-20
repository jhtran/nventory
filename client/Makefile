# When updating the version number you currently need to update
# nventory-client.spec, control and pkginfo as well
VER=1.62.8

all:

redhat: rpmbuild-redhat rpm
rpmbuild-redhat:
	rpm --quiet -q rpm-build || yum -y install rpm-build
BUILDROOT=/var/tmp/nventory-client-buildroot
TMPSPEC = nventory-client-temp.spec
rpm: nventory-client.spec
	#
	# Create package file structure in build root
	#
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/usr/bin
	cat perl/nv|sed "s/@@VERSION@@/$(VER)/g" > $(BUILDROOT)/usr/bin/nv.perl
	chmod 555 $(BUILDROOT)/usr/bin/nv.perl
	cp -p ruby/nv $(BUILDROOT)/usr/bin/nv.ruby
	chmod 555 $(BUILDROOT)/usr/bin/nv.ruby
	# Make the perl client the default client for now
	ln -s nv.perl $(BUILDROOT)/usr/bin/nv
	ln -s nv $(BUILDROOT)/usr/bin/nventory
	mkdir -p $(BUILDROOT)/usr/lib/perl5/site_perl
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/lib/perl5/site_perl)
	mkdir -p $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	cp -p ruby/nventory.rb $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	mkdir -p $(BUILDROOT)/etc/nventory
	cp -p nventory.conf $(BUILDROOT)/etc
	cp -p ca.pem $(BUILDROOT)/etc/nventory
	cp -p dhparams $(BUILDROOT)/etc/nventory
	# Cron job for registration
	mkdir -p $(BUILDROOT)/etc/cron.d
	cp nventory_cron $(BUILDROOT)/etc/cron.d/nventory
	mkdir -p $(BUILDROOT)/usr/sbin
	cp nventory_cron_wrapper $(BUILDROOT)/usr/sbin
	chmod 555 $(BUILDROOT)/usr/sbin/nventory_cron_wrapper
	#
	# Now build the package
	#
	# Prior to RHEL 5 the package containing dmidecode is kernel-utils
	cat nventory-client.spec | sed '/^Requires:/s/$$/, kernel-utils/'|sed "s/@@VERSION@@/$(VER)/g" > $(TMPSPEC)
	rpmbuild -bb --buildroot $(BUILDROOT) $(TMPSPEC)
	mv /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.noarch.rpm /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.el4.noarch.rpm
	# Starting with RHEL 5 dmidecode got its own package
	cat nventory-client.spec | sed '/^Requires:/s/$$/, dmidecode/' > $(TMPSPEC)
	rpmbuild -bb --buildroot $(BUILDROOT) $(TMPSPEC)
	cp /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.noarch.rpm /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.el6.noarch.rpm
	mv /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.noarch.rpm /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.el5.noarch.rpm
	rm -rf $(BUILDROOT) $(TMPSPEC)

debian: control
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/DEBIAN
	grep -v '^#' control|sed "s/@@VERSION@@/$(VER)/g" > $(BUILDROOT)/DEBIAN/control
	mkdir -p $(BUILDROOT)/usr/bin
	cat perl/nv|sed "s/@@VERSION@@/$(VER)/g" > $(BUILDROOT)/usr/bin/nv.perl
	chmod 555 $(BUILDROOT)/usr/bin/nv.perl
	cp -p ruby/nv $(BUILDROOT)/usr/bin/nv.ruby
	chmod 555 $(BUILDROOT)/usr/bin/nv.ruby
	# Make the perl client the default client for now
	ln -s nv.perl $(BUILDROOT)/usr/bin/nv
	ln -s nv $(BUILDROOT)/usr/bin/nventory
	mkdir -p $(BUILDROOT)/usr/local/lib/site_perl/5.10.0
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/local/lib/site_perl/5.10.0)
	mkdir -p $(BUILDROOT)/usr/local/lib/site_ruby/1.8
	cp -p ruby/nventory.rb $(BUILDROOT)/usr/local/lib/site_ruby/1.8
	mkdir -p $(BUILDROOT)/etc/nventory
	cp -p nventory.conf $(BUILDROOT)/etc
	cp -p ca.pem $(BUILDROOT)/etc/nventory
	cp -p dhparams $(BUILDROOT)/etc/nventory
	sudo chown -R 0:0 $(BUILDROOT)
	dpkg --build $(BUILDROOT) nventory-client-$(VER).deb
	sudo rm -rf $(BUILDROOT)

solaris: pkginfo depend
	#
	# Create package file structure in build root
	#
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/usr/bin
	cat perl/nv|sed "s/@@VERSION@@/$(VER)/g" > $(BUILDROOT)/usr/bin/nv.perl
	mv $(BUILDROOT)/usr/bin/nv.perl $(BUILDROOT)/usr/bin/nv.perl.tmp
	cat $(BUILDROOT)/usr/bin/nv.perl.tmp | sed 's,/usr/bin/perl,/opt/csw/bin/perl,' > $(BUILDROOT)/usr/bin/nv.perl
	rm $(BUILDROOT)/usr/bin/nv.perl.tmp
	chmod 555 $(BUILDROOT)/usr/bin/nv.perl
	cp -p ruby/nv $(BUILDROOT)/usr/bin/nv.ruby
	mv $(BUILDROOT)/usr/bin/nv.ruby $(BUILDROOT)/usr/bin/nv.ruby.tmp
	cat $(BUILDROOT)/usr/bin/nv.ruby.tmp | sed 's,/usr/bin/ruby,/opt/csw/bin/ruby,' > $(BUILDROOT)/usr/bin/nv.ruby
	rm $(BUILDROOT)/usr/bin/nv.ruby.tmp
	chmod 555 $(BUILDROOT)/usr/bin/nv.ruby
	# Make the perl client the default client for now
	ln -s nv.perl $(BUILDROOT)/usr/bin/nv
	ln -s nv $(BUILDROOT)/usr/bin/nventory
	mkdir -p $(BUILDROOT)/opt/csw/lib/perl/site_perl
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/opt/csw/lib/perl/site_perl)
	mkdir -p $(BUILDROOT)/usr/nventory
	(cd perl && find 3rdparty | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/nventory)
	mkdir -p $(BUILDROOT)/opt/csw/lib/ruby/site_ruby/1.8
	cp -p ruby/nventory.rb $(BUILDROOT)/opt/csw/lib/ruby/site_ruby/1.8
	mkdir -p $(BUILDROOT)/etc/nventory
	cp -p nventory.conf $(BUILDROOT)/etc
	cp -p ca.pem $(BUILDROOT)/etc/nventory
	cp -p dhparams $(BUILDROOT)/etc/nventory
	# Cron job for registration
	mkdir -p $(BUILDROOT)/usr/sbin
	cat nventory_cron_wrapper | sed 's,/usr/bin/perl,/opt/csw/bin/perl,' > $(BUILDROOT)/usr/sbin/nventory_cron_wrapper
	cat pkginfo | sed "s,@@VERSION@@,$(VER),g" > pkginfo.NEW
	mv pkginfo.NEW pkginfo
	chmod 555 $(BUILDROOT)/usr/sbin/nventory_cron_wrapper
	#
	# Now build the package
	#
	echo "i pkginfo=./pkginfo" > prototype
	echo "i depend=./depend" >> prototype
	echo "i postinstall=./postinstall" >> prototype
	echo "i postremove=./postremove" >> prototype
	# The tail +2 removes the first line, which is the base directory
	# and doesn't need to be included in the package.
	# The first sed just cleans up the directory names
	# The second and third seds tell pkgadd to not force our permissions
	# on /usr and /usr/bin
	find $(BUILDROOT) | pkgproto | tail -n +2 | sed "s,$(BUILDROOT),," | sed 's,/usr .*,/usr ? ? ?,' | sed 's,/usr/bin .*,/usr/bin ? ? ?,' | sed 's,/usr/sbin .*,/usr/sbin ? ? ?,' >> prototype
	pkgmk -r $(BUILDROOT) -d $(PWD)
	pkgtrans . YPCnventory-$(VER).pkg YPCnventory
	rm -rf YPCnventory
	rm -rf $(BUILDROOT)
	rm -f prototype

# This package is for users who want to program against the nventory
# libraries. It is handy for them to be able to install and depend on
# the library along with other tpkgs. In order to reduce confusion this
# package does not contain any of the executables that go in the normal
# packages.
tpkg: tpkg.xml
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/root/opt/tpkg/lib/perl5/site_perl/5.10.0
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/root/opt/tpkg/lib/perl5/site_perl/5.10.0)
	mkdir -p $(BUILDROOT)/root/opt/tpkg/ruby-1.8/lib/ruby/site_ruby/1.8
	sed "s/VER/$(VER)/" tpkg.xml > $(BUILDROOT)/tpkg.xml
	cp -p ruby/nventory.rb $(BUILDROOT)/root/opt/tpkg/ruby-1.8/lib/ruby/site_ruby/1.8
	tpkg --make $(BUILDROOT)
	rm -rf $(BUILDROOT)

