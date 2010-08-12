Name: nventory-client
Summary: nVentory client
Version: 1.62.8
Release: 1
Group: Applications/System
License: MIT
buildarch: noarch
# RPM's automagic dependency handling captures most of our Perl module
#  dependencies.  But perl-Crypt-SSLeay is special because perl-libwww-perl
#  doesn't list it as a dependency, as it only tries to use it if you try
#  to access an HTTPS URL.  So we have to explicitly list it as a dependency
#  to ensure yum pulls it in.
# We also depend on dmidecode, but that is provided by different
#  packages depending on the version of RHEL, so we do some magic
#  in the Makefile to handle that.
# And specify a version dependency on libxml2.  This is required because the
#  perl-XML-LibXML package from DAG's repo, which we use on RHEL 3 because
#  RHEL 3 doesn't include perl-XML-LibXML, isn't properly specifying its
#  dependency on the underlying libxml2 library, so RPM assumes the already
#  installed stock RHEL 3 libxml2 package is fine and doesn't upgrade to
#  the DAG libxml2 package. DAG's libxml2 package is 2.6.16, as is
#  RHEL 4 U0, so we can probably safely specify that as a minimum version
#  for libxml2 in our spec file as a workaround.
Requires: perl-Crypt-SSLeay, crontabs, libxml2 >= 2.6.16, sysstat, lshw, redhat-lsb
BuildRoot: %{_builddir}/%{name}-buildroot
%description
nVentory client

%files
%defattr(-,root,root)
/usr/bin/nv
/usr/bin/nv.perl
/usr/bin/nv.ruby
/usr/bin/nventory
/usr/lib/perl5/site_perl/nVentory
/usr/lib/ruby/site_ruby/1.8/nventory.rb
/etc/cron.d/nventory
/usr/sbin/nventory_cron_wrapper
%config /etc/nventory.conf
%config /etc/nventory/ca.pem
%config /etc/nventory/dhparams

%post
# Run a one-time registration right away
nv --register
