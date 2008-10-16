# When updating the version number you currently need to update
# nventory-client.spec, control and pkginfo as well
VER=1.1

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
	cp -p perl/nv $(BUILDROOT)/usr/bin/nv.perl
	chmod 555 $(BUILDROOT)/usr/bin/nv.perl
	cp -p ruby/nv $(BUILDROOT)/usr/bin/nv.ruby
	chmod 555 $(BUILDROOT)/usr/bin/nv.ruby
	# Make the perl client the default client for now
	ln -s nv.perl $(BUILDROOT)/usr/bin/nv
	mkdir -p $(BUILDROOT)/usr/lib/perl5/site_perl
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/lib/perl5/site_perl)
	mkdir -p $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	cp -p ruby/nventory.rb $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	mkdir -p $(BUILDROOT)/etc/nventory
	cp -p nventory.conf $(BUILDROOT)/etc
	#cp -p ca.pem $(BUILDROOT)/etc/nventory
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
	cat nventory-client.spec | sed '/^Requires:/s/$$/, kernel-utils/' > $(TMPSPEC)
	rpmbuild -bb --buildroot $(BUILDROOT) $(TMPSPEC)
	mv /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.noarch.rpm /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.el4.noarch.rpm
	# Starting with RHEL 5 dmidecode got its own package
	cat nventory-client.spec | sed '/^Requires:/s/$$/, dmidecode/' > $(TMPSPEC)
	rpmbuild -bb --buildroot $(BUILDROOT) $(TMPSPEC)
	mv /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.noarch.rpm /usr/src/redhat/RPMS/noarch/nventory-client-$(VER)-1.el5.noarch.rpm
	rm -rf $(BUILDROOT) $(TMPSPEC)

debian: control
	rm -rf debtmp
	mkdir -p debtmp/DEBIAN
	grep -v '^#' control > debtmp/DEBIAN/control
	mkdir -p debtmp/usr/bin
	cp -p perl/nv debtmp/usr/bin/nv.perl
	chmod 555 debtmp/usr/bin/nv.perl
	cp -p ruby/nv debtmp/usr/bin/nv.ruby
	chmod 555 debtmp/usr/bin/nv.ruby
	# Make the perl client the default client for now
	ln -s nv.perl debtmp/usr/bin/nv
	mkdir -p debtmp/usr/lib/perl5/site_perl
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum debtmp/usr/lib/perl5/site_perl)
	mkdir -p debtmp/usr/lib/ruby/site_ruby/1.8
	cp -p ruby/nventory.rb debtmp/usr/lib/ruby/site_ruby/1.8
	mkdir -p debtmp/etc/nventory
	cp -p nventory.conf debtmp/etc
	#cp -p ca.pem debtmp/etc/nventory
	sudo chown -R 0:0 debtmp
	dpkg --build debtmp nventory-client-$(VER).deb
	rm -rf debtmp

solaris: pkginfo depend
	#
	# Create package file structure in build root
	#
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/usr/bin
	cp -p perl/nv $(BUILDROOT)/usr/bin/nv.perl
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
	mkdir -p $(BUILDROOT)/usr/lib/perl5/site_perl
	(cd perl && find nVentory | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/lib/perl5/site_perl)
	mkdir -p $(BUILDROOT)/usr/nventory
	(cd perl && find 3rdparty | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/nventory)
	mkdir -p $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	cp -p ruby/nventory.rb $(BUILDROOT)/usr/lib/ruby/site_ruby/1.8
	mkdir -p $(BUILDROOT)/etc/nventory
	cp -p nventory.conf $(BUILDROOT)/etc
	#cp -p ca.pem $(BUILDROOT)/etc/nventory
	# Cron job for registration
	mkdir -p $(BUILDROOT)/usr/sbin
	cat nventory_cron_wrapper | sed 's,/usr/bin/perl,/opt/csw/bin/perl,' > $(BUILDROOT)/usr/sbin/nventory_cron_wrapper
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
	find $(BUILDROOT) | pkgproto | tail +2 | sed "s,$(BUILDROOT),," | sed 's,/usr .*,/usr ? ? ?,' | sed 's,/usr/bin .*,/usr/bin ? ? ?,' | sed 's,/usr/sbin .*,/usr/sbin ? ? ?,' >> prototype
	pkgmk -r $(BUILDROOT) -d $(PWD)
	pkgtrans . OSSnventory-$(VER).pkg OSSnventory
	rm -rf OSSnventory
	rm -rf $(BUILDROOT)
	rm -f prototype

