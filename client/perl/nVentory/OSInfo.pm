##############################################################################
# Functions for gathering info about a host's operating system
##############################################################################

package nVentory::OSInfo;

use strict;
use warnings;
use nVentory::HardwareInfo;
use Sys::Hostname;  # hostname
use File::stat;     # Improved stat
use File::Find;     # find

my $debug;

my $hostname;
my $shortname;
my $domainname;
my $fqdn;
my @aliases;
my $os;
my $osversion;
my $osarch;
my $kernelversion;
my $osmemory;
my $swapmemory;
my $cpupercent;
my %oscpus;
my $timezone;
my $virtualstatus;
my $vmwarestatus;
my %virtualhostinfo;
my %vmwarehostinfo;
my %volumes;
my $diskusage;

# Hostname as configured on the system, may or may not be fully
# qualified
sub gethostname
{
	if (!$hostname)
	{
		$hostname = hostname;
	}

	warn "gethostname returning '$hostname'" if ($debug);
	return $hostname;
}

# System hostname with any domain component removed
sub getshortname
{
	if (!$shortname)
	{
		gethostname();
		($shortname) = split(/\./, $hostname);
	}

	warn "getshortname returning '$shortname'" if ($debug);
	return $shortname;
}

sub getvolumes
{
        my %volumes;
        my %mounted = getmountedvolumes();
        foreach my $key (keys %mounted) {
                $volumes{$key} = $mounted{$key};
        }
        my %served = getservedvolumes();
        foreach my $key (keys %served ) {
                $volumes{$key} = $served{$key};
        }
        return %volumes;
}

sub getservedvolumes
{
        my %served;
	my $os = getos();

	if ($os =~ /Linux/)
	{
	        # EXPORTS - nfs exports
                if (-e "/etc/exports") {
 	 	        open(FILE, "/etc/exports");
	                	foreach my $line (<FILE>) {
	                       	 	my ($vol) = $line =~ /(\S+)\s+/;
	                        	if ( -d $vol) {
	                                        $served{"volumes[served][$vol][config]"} = "/etc/exports";
	                                        $served{"volumes[served][$vol][type]"} = 'nfs';
	                        	}
	                	}
	        	close(FILE);
		}
	} # if ($os =~ /Linux/)

        return %served;
}

sub getmountedvolumes
{
	my $os = getos();
        my %mounted;
        my $DIR = "/etc";

	if ($os =~ /Linux/)
	{

	        # AUTOFS - gather only files named auto[._]*
	        opendir(DIR, $DIR);
	                my @all_etc = readdir(DIR);
	        close(DIR);
	        my @autofiles;
	        foreach my $file (@all_etc) {
	                if ( $file =~ /^auto[._].*/ ) {
	                        push(@autofiles, $file)
	                }
	        }
	
	        # AUTOFS - match only lines that look like nfs syntax such as host:/path
	        foreach my $file (@autofiles) {
	                open(FILE ,"$DIR/$file");
	                        my @contents = <FILE>;
	                close(FILE);
	                foreach my $line (@contents) {
	                        if ( ( $line =~ /\w:\S/ ) && ( $line !~ /^\s*#/) ) {
	                                # Parse it, Example : " opsdb_backup    -noatime,intr   irvnetappbk:/vol/opsdb_backup "
	                                (my $mnt, my $host, my $vol) = $line =~ /^(\w[\w\S]+)\s+\S+\s+(\w[\w\S]+):(\S+)/;
	                                if ($mnt && $host && $vol) {
	                                        $mounted{"volumes[mounted][/mnt/$mnt][config]"} = "$DIR/$file";
	                                        $mounted{"volumes[mounted][/mnt/$mnt][volume_server]"} = $host;
	                                        $mounted{"volumes[mounted][/mnt/$mnt][volume]"} = $vol;
	                                        $mounted{"volumes[mounted][/mnt/$mnt][type]"} = 'nfs';
	                                }
	                        } # if ( $line =~ /\w:\S/ ) {
	                } # foreach my $line (@contents) {
	        } # foreach my $file (@autofiles) {
	
	
	        # FSTAB - has diff syntax than AUTOFS.  Example: "server:/usr/local/pub    /pub   nfs    rsize=8192,wsize=8192,timeo=14,intr"
	        open(FILE, "/etc/fstab");
	                my @contents = <FILE>;
	        close(FILE);
	        foreach my $line (@contents) {
	                if ( (my $host, my $vol, my $mnt) = $line =~ /^(\w[\w\S]+):(\S+)\s+(\S+)\s+nfs/ ) {
	                        $mounted{"volumes[mounted][$mnt][config]"} = "/etc/fstab";
	                        $mounted{"volumes[mounted][$mnt][volume_server]"} = $host;
	                        $mounted{"volumes[mounted][$mnt][volume]"} = $vol;
	                        $mounted{"volumes[mounted][$mnt][type]"} = 'nfs';
	                }
	        }
	} # if ($os =~ /Linux/)

        ##### COMPLETED ####
        return %mounted
}

sub getdomainname
{
	if (!$domainname)
	{
		# Check the system hostname
		gethostname();
		if ($hostname && $hostname =~ /\./)
		{
			(undef, $domainname) = split(/\./, $hostname, 2);
		}

		# The next couple of commands might not exist, we don't want the
		# user to have to see output to that effect, since that doesn't
		# necessarily contitute a problem.  So we dump stderr to
		# /dev/null.  Solaris being Solaris, /bin/sh will throw an error
		# out to stderr about the command not being found, but doesn't
		# consider that something that should obey your redirect.  So we
		# wrap the command in () so that it is executed in a subshell,
		# then Solaris /bin/sh redirects the output from the subshell
		# like you'd expect.
		# http://groups.google.com/group/comp.unix.solaris/browse_thread/thread/4a53aea1629b715

		# Try the dnsdomainname command
		if (!$domainname)
		{
			warn "Running 'dnsdomainname'" if ($debug);
			chomp(my $output = `(dnsdomainname) 2> /dev/null`);
			if ($output && $output =~ /\./)
			{
				$domainname = $output;
			}
		}

		# Try the domainname command
		if (!$domainname)
		{
			warn "Running 'domainname'" if ($debug);
			chomp(my $output = `(domainname) 2> /dev/null`);
			if ($output && $output =~ /\./)
			{
				$domainname = $output;
			}
		}

		# Try resolv.conf
		if (!$domainname && -f '/etc/resolv.conf')
		{
			warn "Reading '/etc/resolv.conf'" if ($debug);
			open(my $resconf, '<', '/etc/resolv.conf') or
				die "open /etc/resolv.conf: $!\n";
			my @resconflines = <$resconf>;
			close($resconf);

			# Look for a domain line
			my @domainlines = grep(/^domain\s+\S+/, @resconflines);
			if (@domainlines)
			{
				$domainlines[0] =~ /^domain\s+(\S+)/;
				$domainname = $1;
			}
			if (!$domainname)
			{
				# Look for a search line
				my @searchlines = grep(/^search\s+\S+/, @resconflines);
				if (@searchlines)
				{
					$searchlines[0] =~ /^search\s+(\S+)/;
					$domainname = $1;
				}
			}
		}
	}

	warn "getdomainname returning '$domainname'" if ($debug);
	return $domainname;
}

sub getfqdn
{
	if (!$fqdn)
	{
		getshortname();
		getdomainname();
		if ($shortname && $domainname)
		{
			$fqdn = join('.', $shortname, $domainname);
		}
	}

	warn "getfqdn returning '$fqdn'" if ($debug);
	return $fqdn;
}

sub getaliases
{
	if (!@aliases)
	{
		## GET IPs ##
		my @ips;
		my %nicdata = nVentory::HardwareInfo::getnicdata();
		foreach my $nic (keys %nicdata) {
			foreach my $ipaddr ($nicdata{$nic}->{'ip_addresses'}) {
				if ($ipaddr) {
					foreach my $key (@{$ipaddr}) {
						if ($key->{address_type} eq 'ipv4') { push(@ips, $key->{address}); }
						# attempt to get dns for host
						unless ($key->{address} eq '127.0.0.1') {
							open(HOST, '-|', "host $key->{address}");
								while (<HOST>) {
									if ($_ =~ /domain name pointer\s+(\S+)\./) {
										push(@aliases, $1);
									} # if (my $iphost =~ /domain name pointer
								} # while (<HOST>) {
							close(HOST);
						} # unless ($key->{address} eq '127.0.0.1') {
					} # foreach my $key (@{ipadr}) {
				} # if ($ipaddr) {
			} # foreach my $ipaddr ($nicdata{$nic}->
		} # foreach my $nic (keys %nicdata) { 

		## PARSE HOSTS FILE
		open(HOSTS, '</etc/hosts') or die "open: $!";
			while (<HOSTS>) { 
				if ($_ =~ join('|',@ips)) {
					(my $match) = $_ =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+(\S.*)/;
					if ($match) {
						foreach my $element (split(/\s+/, $match)) {
							push(@aliases, $element) unless $element =~ /localhost/;
						}
					} # if ($match) {
				} # if ($_ =~ join('|',@ips)) {
			} # while (<HOSTS>) {
		close(HOSTS);
	} # if (!@aliases)

	warn "getaliases returning ${\join(', ', @aliases)}" if ($debug);
	return @aliases;
}

sub getvmwarestatus
{
        if (!$vmwarestatus)
        {
                $vmwarestatus = `facter virtual`;
                chomp($vmwarestatus);
        }
        warn "getvmwarestatus returning '$vmwarestatus'" if ($debug);
        return $vmwarestatus;
}

sub getvirtualstatus
{
        if (!$virtualstatus)
        {
                $virtualstatus = `facter virtual`;
                chomp($virtualstatus);
        }
        warn "getvirtualstatus returning '$virtualstatus'" if ($debug);
        return $virtualstatus;
}

sub getvirtualhostinfo
{
	if (!%virtualhostinfo)
	{
		my @virshlist = `virsh list`;
		foreach my $line (@virshlist)
		{
			next if $line =~ /(Id Name|^---|^$|Domain-0)/;
                        $line =~ /\s(\d+)\s(\S+)\s(\S+)/;
			my $guest = $2;
			push(@{$virtualhostinfo{'guests'}}, $guest);
                 }
	}
	return %virtualhostinfo;
}

sub getvmwarehostinfo
{
	if (!%vmwarehostinfo)
	{
		my @content;
		if (-x '/usr/sbin/esxcfg-info')
		{
		        open my $esxcfgfh, '-|', '/usr/sbin/esxcfg-info'
		                or die "open /usr/sbin/esxcfg-info: $!";
		                @content = <$esxcfgfh>;
		        close($esxcfgfh);
		}
		else
		{
		        return;
		}

		# Parse the 'resource leaf' section of output for dir path & uuid
		my %resleafs;
		my @tmpresleaf;
		my $rcounter = 0;
		my $tmpflag = 0;
		
		foreach my $line (@content)
		{
		        if ($line =~ /Config File\.+(\/.*)$/ )
		        {
		                $tmpflag = 1;
		                push(@tmpresleaf, $1);
		        }
		        elsif ($tmpflag == 1)
		        {
		                if ($line =~ /UUID\.+(.*)$/)
		                {
		                        push(@tmpresleaf, $1)
		                }
		                else
		                {
		                        $tmpflag = 0;
		                        $resleafs{$rcounter} = [ @tmpresleaf ];
		                        @tmpresleaf = ();
		                        $rcounter++;
		                }
		        }
		
		} # foreach my $line (@content)

		# Parse the 'ports' section of output for mac data
		my %ports;
		my @tmpport;
		my $pflag = 0;
		my $pcounter = 0;
		foreach my $line (@content)
		{
		        if ($line =~ /\\==\+Port :/)
		        {       
		                $pflag = 1;
		        }
		        if (($pflag == 1) && ($line !~ /\\==\+Stats :/))
		        {       
		                push(@tmpport, $line);
		        }
		        elsif ($pflag == 1)
		        {       
		                $ports{$pcounter} = [ @tmpport ];
		                @tmpport = ();
		                $pcounter++;
		                $pflag = 0;
		        }
		}

		# Create the RESTful hash
		my %data;
		foreach my $key (keys %ports)
		{       
		        # vms are defined by the line 'Type' specifying 'Vmm'
		        my ($tline) = grep(/Type\.+/, @{$ports{$key}});
		        next unless ( $tline =~ /Type\.+Vmm$/ ) ;
		        
		        # we need the name, mac_addr 
		        my ($nline) = grep(/Client Name/, @{$ports{$key}});
		        my ($name) = $nline =~ /Client Name\.+(\w+)$/;
		        my ($mline) = grep(/MAC Addr/, @{$ports{$key}});
		        my ($mac_addr) = $mline =~ /MAC Addr\.+([\w:]+)$/;
		        $data{"vmguest" . '[' . "$name" . ']' . "[mac_addr]"} = $mac_addr;
			
			# (although we ar collecting mac, we do not use it anywhere. Added in case future use)
		}
		
		foreach my $key (keys %resleafs)
		{       
		        my ($vline) = grep( /^\//, @{$resleafs{$key}} );
		        my ($vmdir) = $vline =~ /^(.*)\//;
		        my ($vmname) = $vmdir =~ /\/(\w+)$/;
		        $data{"vmguest" . '[' . "$vmname" . ']' . "[vmimg_dir]"} = $vmdir;
		        my ($size) = `du -sk $vmdir` =~ /^(\d+)/; 
		        $data{"vmguest" . '[' . "$vmname" . ']' . "[vmimg_size]"} = $size;
		        my ($uline) = grep( /^[^\/]/, @{$resleafs{$key}});
		        my ($uuid) = $uline =~ /^(\d.*)$/;
		        $uuid = uc $uuid;
		        my @uuid_parts = split(' ', $uuid);
		        $uuid = sprintf('%s%s%s%s-%s%s-%s%s%s-%s%s%s%s%s%s', @uuid_parts);
		        $data{"vmguest" . '[' . "$vmname" . ']' . "[uuid]"} = $uuid;

			# (although we ar collecting uuid and vmdir, we do not use them anywhere. Added in case future use)
		}

		return %data;
	} # if (!%vmwarehostinfo)
} # sub getvmwarehostinfo

sub getdiskusage
{
	if (!$diskusage)
	{
		open(DISKU,  "-|", "df -k");
		  my @content = <DISKU>;
		close(DISKU);
		
		my %disk_usage;
		my @all_used_space;
		my @all_avail_space;
		foreach my $line (@content) {
		  if ($line =~ /\s+\d+\s+(\d+)\s+(\d+)\s+\d+%\s+\/($|home$)/) {
		    push(@all_used_space, $1);
		    push(@all_avail_space, $2);
		  }
		}
		
		my $used_space;
		foreach (@all_used_space) { $used_space += $_ };
		# convert to KB
		$disk_usage{used_space} = round($used_space);
		my $avail_space;
		foreach (@all_avail_space) { $avail_space += $_ };
		$disk_usage{avail_space} = round($avail_space);
		return %disk_usage;
	}
}

sub round 
{
	my($number) = shift;
  	if ((int($number + .5)) == 0) {
    		return 1;
  	} else {
    		return int($number + .5);
  	}
}

sub getos
{
	if (!$os)
	{
		warn "Running 'uname -s'" if ($debug);
		chomp(my $tempos = `uname -s`);
		my $temposversion = getkernelversion();

		if ($tempos eq 'Linux')
		{
			if (-f '/etc/redhat-release')
			{
				warn "Reading '/etc/redhat-release'" if ($debug);
				open(RR, '<', '/etc/redhat-release') or die "open: $!";
				my $rr = <RR>;
				close(RR);
				if ($rr =~ /(Red Hat Linux) release ([\d\.]+)/)
				{
					$os = $1;
					$osversion = $2;
				}
				elsif ($rr =~ /Red Hat Linux Advanced Server release ([\d\.]+)/)
				{
					# Fake this up to look like the newer RHEL entries,
					# which matches Red Hat's rebranding of Advanced Server
					# and makes pattern matching against the entries easier.
					$os = 'Red Hat Enterprise Linux AS';
					$osversion = $1;
				}
				elsif ($rr =~ 
					/(Red Hat Enterprise Linux (?:AS|ES|WS|Server)) release ([\d\.]+)(?: \(\w+ Update (\d+)\))?/)
				{
					$os = $1;
					my $majorver = $2;
					my $minorver;
					if ($3)
					{
						$minorver = $3;
					}
					else
					{
						$minorver = 0;
					}

					# Starting with RHEL 5 the "release X.X" number is the
					# complete version, only the code name is in the following
					# parenthesis.  Previous versions of RHEL just listed the
					# major version number in the "release X" area, the update
					# number was hidden in the parenthesis.
					if ($majorver =~ /\./)
					{
						$osversion = $majorver
					}
					else
					{
						$osversion = "$majorver.$minorver";
					}
				}
				elsif ($rr =~ /(Fedora(?: Core)?) release ([\d\.]+)/)
				{
					# Expand the OS name to include some extra terms
					# that will make pattern matching for Linux or Red
					# Hat products easier.
					$os = "Red Hat $1 Linux";
					$osversion = $2;
				}
				elsif ($rr =~ /(CentOS) release ([\d\.]+)/)
				{
					# Expand the OS name to include some extra terms
					# that will make pattern matching for Linux or Red
					# Hat products easier.
					$os = "Red Hat $1 Linux";
					$osversion = $2;
					
					# In CentOS 5.1 it appears that the CentOS folks
					# forgot to update /etc/redhat-release, and the
					# file looks the same as CentOS 5.0.  However, they
					# did update the centos-release RPM, so check the
					# version number of that package to distinguish
					# between the two.
					if ($osversion eq '5')
					{
						warn "Running 'rpm -q centos-release'" if ($debug);
						if (`rpm -q centos-release` =~ /centos-release-5-1/)
						{
							$osversion = '5.1';
						}
					}
				}
				else
				{
					die "Failed to parse contents of /etc/redhat-release\n";
				}

				# VMware ESX rides on top of a copy of Red Hat.  We want
				# the string we return for the OS to represent that it is
				# fundamentally a Red Hat box with some customization.
				if (-f '/etc/vmware-release')
				{
					warn "Reading '/etc/vmware-release'" if ($debug);
					open(my $VR, '<', '/etc/vmware-release') or
						die "open /etc/vmware-release: $!\n";
					my $vr = <$VR>;  # Read the first line
					close($VR);
					chomp $vr;
					$os = "$os ($vr)";
				}
			}
			elsif (-f '/etc/SuSE-release')
			{
				warn "Reading '/etc/SuSE-release'" if ($debug);
				open(my $SR, '<', '/etc/SuSE-release') or
					die "open /etc/SuSE-release: $!\n";
				chomp(my $sr = <$SR>);
				close($SR);
				if ($sr =~ /(SUSE|openSUSE)(?: LINUX)? ([\w\.]+)/)
				{
					$os = $1;
					$osversion = $2;
					if ($os !~ /Linux/)
					{
						$os .= ' Linux';
					}
				}
				else
				{
					die "Failed to parse contents of /etc/SuSE-release\n";
				}
			}
			# Ubuntu, possibly others
			elsif (-f '/etc/lsb-release')
			{
				warn "Reading '/etc/lsb-release'" if ($debug);
				open(my $LSB, '<', '/etc/lsb-release') or
					die "open /etc/lsb-release: $!\n";
				while(<$LSB>)
				{
					chomp;
					if (/^DISTRIB_ID=(.*)/)
					{
						$os = $1;
						if ($os !~ /Linux/)
						{
							$os .= ' Linux';
						}
					}
					if (/^DISTRIB_RELEASE=(.*)/)
					{
						$osversion = $1;
					}
				}
				close($LSB);

				if (!$os || !$osversion)
				{
					die "Failed to parse contents of /etc/lsb-release\n";
				}
			}
			elsif (-f '/etc/debian_version')
			{
				$os = 'Debian Linux';
				warn "Reading '/etc/debian_version'" if ($debug);
				open(DV, '<', '/etc/debian_version') or die "open: $!";
				chomp(my $dv = <DV>);
				close(DV);
				$osversion = $dv;
			}
			elsif (-f '/etc/gentoo-release')
			{
				warn "Reading '/etc/gentoo-release'" if ($debug);
				open(my $GR, '<', '/etc/gentoo-release') or
					die "open /etc/gentoo-release: $!\n";
				my $gr = <$GR>;  # Read the first line
				close($GR);
				if ($gr =~ /Gentoo Base System version ([\d\.]+)/)
				{
					$os = 'Gentoo Linux';
					$osversion = $1;
				}
				else
				{
					die "Failed to parse contents of /etc/gentoo-release\n";
				}
			}
			else
			{
				$os = $tempos;
				$osversion = $temposversion;
			}
		}
		elsif ($tempos eq 'Darwin')
		{
			warn "Running 'system_profiler SPSoftwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPSoftwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/System Version: ([\w\s]+) ([\d\.]+)/)
				{
					$os = $1;
					$osversion = $2;
				}
			}
			close(SP);

			if (!$os || !$osversion)
			{
				die "Failed to parse OS info from system_profiler\n";
			}
		}
		else
		{
			$os = $tempos;
			$osversion = $temposversion;
		}

	}

	warn "getos returning '$os'" if ($debug);
	return $os;
}

sub getosversion
{
	# $osversion is set as a side-effect of getos()
	getos() if (!$osversion);

	warn "getosversion returning '$osversion'" if ($debug);
	return $osversion;
}

# OS architecture
sub getosarch
{
	if (!$osarch)
	{
		getos() if (!$os);

		if ($os eq 'SunOS')
		{
			warn "Running 'isainfo -n'" if ($debug);
			chomp($osarch = `isainfo -n`);
		}
		else
		{
			warn "Running 'uname -m'" if ($debug);
			chomp($osarch = `uname -m`);
		}
	}

	warn "getosarch returning '$osarch'" if ($debug);
	return $osarch;
}

sub getkernelversion
{
	if (!$kernelversion)
	{
		warn "Running 'uname -r'" if ($debug);
		chomp($kernelversion = `uname -r`);
	}

	warn "getkernelversion returning '$kernelversion'" if ($debug);
	return $kernelversion;
}

sub getosmemory
{
	if (!$osmemory)
	{
		my $os = getos();

		if ($os =~ /Linux/)
		{
			warn "Running 'free -m'" if ($debug);
			open(FREE, '-|', 'free -m') or die "open: $!";
			while(<FREE>)
			{
				if (/^Mem:\s+(\d+)/)
				{
					$osmemory = $1;
				}
				elsif (/^Swap:\s+(\d+)/)
				{
					$swapmemory = $1;
				}
			}
			close(FREE);
		}
		elsif ($os eq 'FreeBSD' || $os eq 'Darwin' || $os eq 'Mac OS X')
		{
			warn "Running 'sysctl hw.physmem'" if ($debug);
			open(PHYSMEM, '-|', 'sysctl hw.physmem') or die "open: $!";
			while(<PHYSMEM>)
			{
				if (/^hw.physmem:\s+(\d+)/)
				{
					# Convert from bytes to MB
					$osmemory = int($1 / 1024 / 1024);
				}
			}
			close(PHYSMEM);
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'prtconf'" if ($debug);
			open(PRTCONF, '-|', 'prtconf') or die "open: $!";
			while(<PRTCONF>)
			{
				if (/Memory size: (\d+)/)
				{
					$osmemory = $1;
					last;
				}
			}
			close(PRTCONF);
		}
		else
		{
			die; # FIXME
		}
	}

	warn "getosmemory returning '$osmemory'" if ($debug);
	return $osmemory;
}

sub getlogincount
{
	my $os = getos();

	#if ($os =~ /(Linux)/)
	if ($os)
	{
                # How many hours of data we need to sample, not to exceed 24h
                my $minus_hours = 3;

                # get unix cmd 'last' content
                my @content;
                open(LASTDATA,"-|","last");
                        @content = <LASTDATA>;
                close(LASTDATA);

                my $counter ;
                while ($minus_hours >= 0)
                {
                        my ($wkday,$month,$day,$time,$year) = split(/\s+/, localtime(time - $minus_hours * 60 * 60));
                        $time =~ s/:.*//g;
                        $day =~ $1 if ($day =~ /^0(\d)$/);
                        $minus_hours -= 1;
                        foreach my $line (@content)
                        {
                                $counter++ if ($line =~ /$month\s+$day\s+$time/) ;
                        }
                }
		# if null value, then counter should be zero
		$counter = 0 unless ($counter);
                return $counter;
	}
}

sub getcpupercent
{
	if(!$cpupercent)
	{
		my $os = getos();

		if ($os =~ /(Linux)/)
		{
			warn "Running sar -u" if ($debug);
			# How many hours of data we need to sample, not to exceed 24h
			my $minus_hours = 3;
			my $sar_dir = '/var/log/sa';
			
			# right now
			my ($now_y, $now_mo, $now_d, $now_h, $now_mi) = (localtime)[5,4,3,2,1];
			$now_mo++;
			# Perl years begin at 1900
			$now_y += 1900;
			
			# earlier
			my ($before_y, $before_mo, $before_d, $before_h, $before_mi) = (localtime(time - $minus_hours * 60 * 60))[5,4,3,2,1];
			$before_mo++;
			# Perl years begin at 1900
			$before_y += 1900;

			### MAIN EXECUTION ###
			
			# are all sample hours in same day?
			if ($now_d != $before_d) {
			  my @all;
			  my @today_hours = get_today_hours($now_h);
			  my @before_hours = get_before_hours($now_h);
			
			  # Parse today's sar data
			  my @today_sar = get_sar_data($sar_dir);
			  if ((!@today_sar) || (@today_sar eq 'false')) { return 'false'; }
  			  foreach my $hour (@today_hours) {
  			    foreach my $line (@today_sar) {
  			      push(@all, $1) if ($line =~ /^$hour:.*\s(\S+)$/) ;
  			    }
  			  }
			
			  # Parse prior day's sar data
			  my @before_sar = get_sar_data($sar_dir,$before_d);
			  if ((!@before_sar) || (@before_sar eq 'false')) { return 'false'; }
			  foreach my $hour (@before_hours) {
			    foreach my $line (@before_sar) {
			      push(@all, $1) if ($line =~ /^$hour:.*\s(\S+)$/) ;
			    }
			  }
			
			  # create the average #
			  my $sum;
			  foreach (@all) { $sum += $_ };
			  my $avg = ($sum / scalar @all);
			  
			  # sar reports % idle, so need the opposite
			  my $cpupercent = (100 - $avg);
  			  $cpupercent = round($cpupercent);
			  warn "getcpupercent returning '$cpupercent'" if ($debug);
        		  return $cpupercent
			} else {
			  # all hours in same day so just make list of all hours to look for
			  my @all ;
			  my @today_hours = get_today_hours($now_h);
			  
			  # Parse today's sar data
			  my @today_sar = get_sar_data($sar_dir);
			  if ((!@today_sar) || (@today_sar eq 'false')) { return 'false'; }
			  
			  foreach my $hour (@today_hours) {
			    foreach my $line (@today_sar) {
			      push(@all, $1) if ($line =~ /^$hour:.*\s(\S+)$/) ;
			    }
			  }
			
                          return 0 unless @all;
			  # create the average #
			  my $sum;
			  foreach (@all) { $sum += $_ };
			  my $avg = ($sum / scalar @all);
			  
			  # sar reports % idle, so need the opposite
			  my $cpupercent = (100 - $avg);
  			  $cpupercent = round($cpupercent);
			  warn "getcpupercent returning '$cpupercent'" if ($debug);
        		  return $cpupercent
			}
			
			#### SUBROUTINES ####
			
			sub get_before_hours {
			  my $now_h = $_[0];
                          my $minus_hours = 3;
			  # hours range from yesterday
			  my $today_count = $now_h;
			  my $before_count = $minus_hours - $today_count;
			  my @before_range;  
			  foreach my $hour ( ((24 - $before_count)..23) ) {
			    if ($hour =~ /^([0-9])$/) { $hour = "0$hour"; }
			    push(@before_range, $hour);
			  }
			  return @before_range;
			}
			
			sub get_today_hours {
			  my $now_h = $_[0];
			  # determine how many hours today and hour many hours yesterday
			  my $today_count = $now_h;
			  my @today_range; 
			  foreach my $hour ( (0..$today_count) ) {
			    if ($hour =~ /^([0-9])$/) { $hour = "0$hour"; }
			    push(@today_range, $hour);
			  }
			  return @today_range;
			}
			
			sub get_sar_data {
			  my $sar_dir = $_[0];
			  my $day;
			  if ($_[1]) { 
			    if ($_[1] =~ /^([0-9])$/) { 
			      $day = "0$_[1]"; 
			    } else {
			      $day = "$_[1]"; 
			    }
			  }
			  my @content;
			  my @tempcontent;
			  if ($day && ($day > 0)) { 
			    unless(open(SARDATA, "-|", "LC_TIME=POSIX sar -u -f $sar_dir/sa$day")) { return 'false' }
			      @tempcontent = <SARDATA>;
			    close(SARDATA);
			  } else {
			    unless(open(SARDATA, "-|", "LC_TIME=POSIX sar -u")) { return 'false' }
			      @tempcontent = <SARDATA>;
			    close(SARDATA);
			  }
			
			  foreach my $line (@tempcontent) {
			    push(@content, $line) unless ($line =~ /(average|cpu|%|linux)/i);
			  }
			  return @content;
		       }
		}
	}
}

sub getswapmemory
{
	if (!$swapmemory)
	{
		my $os = getos();

		if ($os =~ /Linux/)
		{
			# Swap info is gathered as a side-effect on Linux
			getosmemory();
		}
		elsif ($os eq 'FreeBSD')
		{
			warn "Running 'swapinfo'" if ($debug);
			open(SWAPINFO, '-|', 'swapinfo') or die "open: $!";
			while(<SWAPINFO>)
			{
				if (/^Total\s+(\d+)/)
				{
					$swapmemory = $1;
				}
			}
			close(SWAPINFO);
		}
		elsif ($os eq 'SunOS')
		{
			my $swapblks;
			warn "Running 'swap -l'" if ($debug);
			open(SWAP, '-|', 'swap -l') or die "open: $!";
			while(<SWAP>)
			{
				if (/(\d+)\s+(\d+)$/)
				{
					$swapblks += $1;
				}
			}
			close(SWAP);

			# Convert from 512-byte blocks to MB
			$swapmemory = int($swapblks / 2 / 1024);
		}
		elsif ($os eq 'Darwin' || $os eq 'Mac OS X')
		{
				# FIXME: Should figure out where dynamic_pager has been
				# configured to write, this assumes the default location
				my $SWAPDIR = '/private/var/vm';
				my $tmpswapmem = 0;
				opendir(VMDIR, $SWAPDIR) or die "opendir: $!";
				while (my $entry = readdir(VMDIR))
				{
					if ($entry =~ /^swapfile\d+$/)
					{
						my $st = stat("$SWAPDIR/$entry") or die "stat: $!";
						$tmpswapmem += $st->size;
					}
				}
				closedir(VMDIR);

				# Convert from bytes to MB
				$swapmemory = int($tmpswapmem / 1024 / 1024);
		}
		else
		{
			die; # FIXME
		}
	}

	warn "getswapmemory returning '$swapmemory'" if ($debug);
	return $swapmemory;
}

# This returns the number of physical CPUs that the OS sees.  This
# counts physical CPUs (same definition of a physical CPU as get_cpu_count
# in HardwareInfo.pm).  The number of CPUs seen by the OS can be
# different from the number of physical CPUs.  One common example is a
# system with multiple CPUs running a non-SMP kernel.
sub get_os_cpu_count
{
	if (!%oscpus)
	{
		my $os = getos();
		if ($os =~ /Linux/)
		{
			# Physical CPUs seen by OS 
			my %cpus;
			# Virtual CPUs
			my %vcpus;
			# Each unique physical id represents a physical CPU.  Duplicate
			# physical ids represent multiple cores, hyper threads or some
			# other form of virtual processor.
			open my $cpuinfofh, '<', '/proc/cpuinfo' or die "open: $!";
			while (<$cpuinfofh>)
			{
				if (/^physical id\s*: (\d+)/)
				{
					$cpus{$1} = 1;
				}
				if (/^processor\s*: (\d+)/)
				{
					$vcpus{$1} = 1;
				}
			}
			close $cpuinfofh;

			# Older combinations of hardware and kernel don't report
			# physical id in /proc/cpuinfo, so we might not have any
			# data in %cpus
			if (%cpus || %vcpus)
			{
				$oscpus{physical} = scalar keys %cpus;
				$oscpus{virtual} = scalar keys %vcpus;
			}
		}
		elsif ($os eq 'FreeBSD')
		{
			# FIXME
		}
		elsif ($os eq 'SunOS')
		{
			my $tempcount;
			warn "Running 'psrinfo -v'" if ($debug);
			open my $psrinfofh, '-|', 'psrinfo', '-v'
				or die "open psrinfo -v: $!";
			while (<$psrinfofh>)
			{
				if (/^Status of/)
				{
					$tempcount++;
				}
			}
			close $psrinfofh;
			$oscpus{physical} = $tempcount;
		}
		elsif ($os eq 'Mac OS X')
		{
			# It's not clear if system_profiler is reporting the number
			# of physical CPUs or the number seen by the OS.  I'm not
			# sure if there are situations in Mac OS where those two can
			# get out of sync.  As such this is identical to get_cpu_count
			# in HardwareInfo.pm.
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Number Of Processors: (\d+)/)
				{
					$oscpus{physical} = $1;
				}
			}
			close(SP);

			if (!%oscpus)
			{
				die "Failed to parse OS CPU count from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}
	warn "get_os_cpu_count returning $oscpus{physical} physical CPUs and $oscpus{virtual} virtual CPUs" if ($debug);
	return %oscpus;
}

sub get_timezone
{
	if (!$timezone)
	{
		my $os = getos();

		if ($os eq 'SunOS')
		{
			open my $tzfh, '<', '/etc/TIMEZONE' or die "open: $!";
			while (<$tzfh>)
			{
				if (/^\s*TZ=['"]?(.*)['"]?/)
				{
					$timezone = $1;
				}
			}
			close $tzfh;
		}
		elsif (-l '/etc/localtime')
		{
			my $dest = readlink '/etc/localtime';
			if ($dest =~ m,zoneinfo/(.*),)
			{
				$timezone = $1;
			}
		}
		elsif (-f '/etc/localtime')
		{
			# Blech, /etc/localtime is a copy of the zoneinfo file.  Some
			# Linux distros do this by default.  Best I can tell the name
			# of the zone is not embedded in the file, so we have to poke
			# through the zoneinfo files to try to find one that matches
			# /etc/localtime.
			if (-d '/usr/share/zoneinfo')
			{
				my $st = stat('/etc/localtime') or die "stat: $!";
				our $ltsize = $st->size;
				open my $ltfh, '<', '/etc/localtime' or die "open: $!";
				our $ltcontents = do { local $/; <$ltfh> };
				close $ltfh;

				# first check the one returned by date shell command
				my $datetz = `date +%Z`;
				chomp($datetz);
				my $datetzf = "/usr/share/zoneinfo/$datetz";
				if (-f $datetzf) {
					my $st = stat($datetzf);
					if ($st->size == $ltsize) {
						open my $zfh, '<', $datetzf or die "open: $!";
						my $zcontents = do { local $/; <$zfh> };
						close $zfh;
						$timezone = $datetz if ($zcontents eq $ltcontents);
					}
				}
				
				# if not a match try other timezones
				find(\&zonematch, '/usr/share/zoneinfo');

				sub zonematch
				{
					# Bail if we've already found a match
					return if ($timezone);
					
					if (-f $_)
					{
						my $st = stat($_) or die "stat: $!";
						# Check the file size first to cut down on the
						# amount of disk reads
						if ($st->size == $ltsize)
						{
							open my $zfh, '<', $_ or die "open: $!";
							my $zcontents = do { local $/; <$zfh> };
							close $zfh;
							if ($zcontents eq $ltcontents)
							{
								my $tempzone = $File::Find::name;
								$tempzone =~ s,.*zoneinfo/,,;
								$tempzone =~ s,posix/,,;
								$timezone = $tempzone;
							}
						}
					}
				}
			}
		}
	}

	warn "get_timezone returning '$timezone'" if ($debug);
	return $timezone;
}

# This does a numerical comparison of numbers with multiple decimal
# points, a format commonly used for version numbers.  An example would
# be "2.5.1".  If you pass "2.5.1" and "2.6" for comparison then "2.6"
# will be converted to "2.6.0" so that both numbers have the name number
# of fields to compare.  Return values match Perl's <=> operator.
#
# This subroutine seems overly complicated, but a simpler implementation
# is eluding me.
sub compare_versions
{
    my $first = shift or die "BUG:  First number not received";
    my $second = shift or die "BUG:  Second number not received";

    # Split each into an array which we can loop through
    my @firstfields = split(/\./, $first);
    my @secondfields = split(/\./, $second);

    # Even out the field counts if needed
    my $fcount = scalar(@firstfields);
    my $scount = scalar(@secondfields);
    if ($fcount > $scount)
    {
        for(my $i=0; $i<($fcount-$scount); $i++)
        {
            push(@secondfields, 0);
        }
    }
    elsif ($scount > $fcount)
    {
        for(my $i=0; $i<($scount-$fcount); $i++)
        {
            push(@firstfields, 0);
        }
    }

    # Compare
    for(my $i=0; $i<scalar(@firstfields); $i++)
    {
        if ($firstfields[$i] != $secondfields[$i])
        {
            return $firstfields[$i] <=> $secondfields[$i];
        }
    }

    # If we get here then the numbers are the same
    return 0;
}

sub setdebug
{
	my ($newdebug) = @_;
	$debug = $newdebug;
}

1;

