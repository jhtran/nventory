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
	mkdir -p $(BUILDROOT)/usr/nventory
	# The 3rdparty utils are currently used only on Solaris, and as at
	# least one of them is written in Perl and requires Solaris-specific
	# modules it throws off RPM's automatic dependency checking
	find perl ruby | grep -v '\.svn' | grep -v 3rdparty | cpio -pdum $(BUILDROOT)/usr/nventory
	chmod 555 $(BUILDROOT)/usr/nventory/perl/nv
	chmod 555 $(BUILDROOT)/usr/nventory/ruby/nv
	mkdir -p $(BUILDROOT)/usr/bin
	# Make the perl client the default client for now
	ln -s /usr/nventory/perl/nv $(BUILDROOT)/usr/bin/nv
	# Cron job for registration
	mkdir -p $(BUILDROOT)/etc/cron.d
	cp nventory_cron $(BUILDROOT)/etc/cron.d/nventory
	cp nventory_cron_wrapper $(BUILDROOT)/usr/nventory
	chmod 555 $(BUILDROOT)/usr/nventory/nventory_cron_wrapper
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
	mkdir -p debtmp/usr/nventory
	find perl ruby | grep -v '\.svn' | cpio -pdum debtmp
	chmod 555 debtmp/usr/nventory/perl/nv
	chmod 555 debtmp/usr/nventory/ruby/nv
	mkdir -p debtmp/usr/bin
	# Make the perl client the default client for now
	ln -s /usr/nventory/perl/nv debtmp/usr/bin/nv
	sudo chown -R 0:0 debtmp
	dpkg --build debtmp nventory-client-$(VER).deb
	rm -rf debtmp

solaris: pkginfo depend
	#
	# Create package file structure in build root
	#
	rm -rf $(BUILDROOT)
	mkdir -p $(BUILDROOT)/usr/nventory
	find perl ruby | grep -v '\.svn' | cpio -pdum $(BUILDROOT)/usr/nventory
	mv $(BUILDROOT)/usr/nventory/perl/nv $(BUILDROOT)/usr/nventory/perl/nv.tmp
	cat $(BUILDROOT)/usr/nventory/perl/nv.tmp | sed 's,/usr/bin/perl,/opt/csw/bin/perl,' > $(BUILDROOT)/usr/nventory/perl/nv
	rm $(BUILDROOT)/usr/nventory/perl/nv.tmp
	chmod 555 $(BUILDROOT)/usr/nventory/perl/nv
	mv $(BUILDROOT)/usr/nventory/ruby/nv $(BUILDROOT)/usr/nventory/ruby/nv.tmp
	# FIXME: Need to express dependency on CSW ruby package
	cat $(BUILDROOT)/usr/nventory/ruby/nv.tmp | sed 's,/usr/bin/ruby,/opt/csw/bin/ruby,' > $(BUILDROOT)/usr/nventory/ruby/nv
	rm $(BUILDROOT)/usr/nventory/ruby/nv.tmp
	chmod 555 $(BUILDROOT)/usr/nventory/ruby/nv
	mkdir -p $(BUILDROOT)/usr/bin
	# Make the perl client the default client for now
	ln -s /usr/nventory/perl/nv $(BUILDROOT)/usr/bin/nv
	# Cron job for registration
	cat nventory_cron_wrapper | sed 's,/usr/bin/perl,/opt/csw/bin/perl,' > $(BUILDROOT)/usr/nventory/nventory_cron_wrapper
	chmod 555 $(BUILDROOT)/usr/nventory/nventory_cron_wrapper
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
	find $(BUILDROOT) | pkgproto | tail +2 | sed "s,$(BUILDROOT),," | sed 's,/usr .*,/usr ? ? ?,' | sed 's,/usr/bin .*,/usr/bin ? ? ?,' >> prototype
	pkgmk -r $(BUILDROOT) -d $(PWD)
	pkgtrans . OSSnventory-$(VER).pkg OSSnventory
	rm -rf OSSnventory
	rm -rf $(BUILDROOT)
	rm -f prototype

