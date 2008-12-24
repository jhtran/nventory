##############################################################################
# Functions for gathering info about a host's operating system
##############################################################################

package nVentory::OSInfo;

use strict;
use warnings;
use Sys::Hostname;  # hostname
use File::stat;     # Improved stat
use File::Find;     # find

my $debug;

my $hostname;
my $shortname;
my $domainname;
my $fqdn;
my $os;
my $osversion;
my $osarch;
my $kernelversion;
my $osmemory;
my $swapmemory;
my $os_cpu_count;
my $timezone;
my $virtual_client_ids;

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
	if (!$os_cpu_count)
	{
		my $os = getos();

		if ($os =~ /Linux/)
		{
			my %cpus;
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
			}
			close $cpuinfofh;

			# Older combinations of hardware and kernel don't report
			# physical id in /proc/cpuinfo, so we might not have any
			# data in %cpus
			if (%cpus)
			{
				$os_cpu_count = scalar keys %cpus;
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
			$os_cpu_count = $tempcount;
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
					$os_cpu_count = $1;
				}
			}
			close(SP);

			if (!$os_cpu_count)
			{
				die "Failed to parse OS CPU count from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_os_cpu_count returning '$os_cpu_count'" if ($debug);
	return $os_cpu_count;
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

sub get_virtual_client_ids
{
	if (!$virtual_client_ids)
	{
		my @virtual_client_ids;
		
		if (-x '/usr/sbin/esxcfg-info')
		{
			warn "Running '/usr/sbin/esxcfg-info'" if ($debug);
			open my $esxcfgfh, '-|', '/usr/sbin/esxcfg-info'
				or die "open /usr/sbin/esxcfg-info: $!";
			while (<$esxcfgfh>)
			{
				# It would be nice to limit this to VMs that are actually
				# running, as ones that are shut down have a higher
				# probability of having been moved to another server or
				# abandoned.
				chomp;
				if (/^\s+\|----UUID\.+([\da-fA-F \-]+)$/)
				{
					my $uuid = $1;
					# Process the UUID to be in the format reported via
					# smbios on virtual clients
					# As reported by esxcfg-info:
					# 56 4d b9 41 e3 59 2c d7-f5 db cc c0 85 73 b2 4b
					# As reported via smbios:
					# 564DB941-E359-2CD7-F5DB-CCC08573B24B
					$uuid = uc $uuid;
					my @uuid_parts = split(' ', $uuid);
					$uuid = sprintf('%s%s%s%s-%s%s-%s%s%s-%s%s%s%s%s%s', @uuid_parts);
					push @virtual_client_ids, $uuid;
				}
			}
			close $esxcfgfh;
		}

		$virtual_client_ids = join(' ', @virtual_client_ids);
	}

	warn "get_virtual_client_ids returning '$virtual_client_ids'" if ($debug);
	return $virtual_client_ids;
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

