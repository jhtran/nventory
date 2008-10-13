##############################################################################
# Functions for gathering info about a host's hardware
##############################################################################

package nVentory::HardwareInfo;

use strict;
use warnings;
use nVentory::OSInfo;
use IPC::Open3;
use Data::Dumper;

my $debug;

my $host_manufacturer;
my $host_model;
my $host_serial;
my $cpu_manufacturer;
my $cpu_model;
my $cpu_speed;
my $cpu_count;
my $cpu_core_count;
my $cpu_socket_count;
my $physical_memory;
my @physical_memory_sizes;
my $uniqueid;
my $power_supply_count;
my $first_nic_hwaddr;
my %dmidata;
my %nicdata;

sub get_host_manufacturer
{
	if (!$host_manufacturer)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$host_manufacturer = $dmidata{'System Information'}[0]->{'Manufacturer'};
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64'))
		{
			if (nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
			{
				_getsmbiosdata();
			}
			else # Solaris x86 <= 5.9
			{
				warn "Running 'uname -s'" if ($debug);
				my $unamei=`uname -i`;
				chomp $unamei;
				warn "Running '/usr/platform/$unamei/sbin/prtdiag'" if ($debug);
				open my $prtdiagfh, '-|', "/usr/platform/$unamei/sbin/prtdiag"
					or die "open prtdiag: $!";
				while (<$prtdiagfh>)
				{
					if (/System Configuration: (.+)/)
					{
						# FIXME: This is extremely fragile (the spliting
						# of the field on the first space to distinguish
						# manufacturer from model)
						($host_manufacturer, $host_model) = split(' ', $1, 2);
						last;
					}
				}
				close $prtdiagfh;
			}
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'uname -i'" if ($debug);
			my $unamei = `uname -i`;
			chomp $unamei;
			($host_manufacturer, $host_model) = split(/,/, $unamei);
		}
		elsif ($os eq 'Mac OS X')
		{
			# FIXME
			$host_manufacturer = 'Apple'
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_host_manufacturer returning '$host_manufacturer'" if ($debug);
	return $host_manufacturer;
}

sub get_host_model
{
	if (!$host_model)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$host_model = $dmidata{'System Information'}[0]->{'Product Name'};
		}
		elsif ($os eq 'SunOS')
		{
			get_host_manufacturer();
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Model Name: (.+)/)
				{
					$host_model = $1;
				}
			}
			close(SP);

			if (!$host_model)
			{
				die "Failed to parse model name from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_host_model returning '$host_model'" if ($debug);
	return $host_model;
}

sub get_host_serial
{
	if (!$host_serial)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$host_serial = $dmidata{'System Information'}[0]->{'Serial Number'};
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			# Host serial numbers are not generally accessible from
			# software on Solaris systems
			$host_serial = '';
			# But can be queried on some Fujitsu systems
			if (-x '/opt/FJSVmadm/sbin/serialid')
			{
				warn "Running '/opt/FJSVmadm/sbin/serialid'" if ($debug);
				my $tmpserial = `/opt/FJSVmadm/sbin/serialid`;
				chomp $tmpserial;
				if ($tmpserial ne 'Not supported on this system')
				{
					$host_serial = $tmpserial;
				}
			}
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Serial Number: (.+)/)
				{
					$host_serial = $1;
				}
			}
			close(SP);

			if (!$host_serial)
			{
				die "Failed to parse serial number from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_host_serial returning '$host_serial'" if ($debug);
	return $host_serial;
}

sub get_cpu_manufacturer
{
	if (!$cpu_manufacturer)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$cpu_manufacturer = $dmidata{'Processor Information'}[0]->{'Manufacturer'};
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64'))
		{
			if (nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
			{
				_getsmbiosdata();
			}
			else # Solaris x86 <= 5.9
			{
				# FIXME
				$cpu_manufacturer = '';
				$cpu_model = '';
			}
		}
		elsif ($os eq 'SunOS') # SPARC
		{
			get_host_model();
			# Might consider switching to memconf for this info, it has
			# much more thorough coverage of the various models.
			warn "Running 'sysdef -d'" if ($debug);
			open my $sysdeffh, '-|', 'sysdef', '-d'
				or die "open sysdef -d: $!";
			while (<$sysdeffh>)
			{
				# Ok, this is going to sound amazing but here goes.  We're
				# looking for Node entries that are one tab stop in and
				# contain a comma.  Then for Ultras we want the entry that
				# isn't SUNW,ffb and for others we want anything that doesn't
				# start with SUNW.  For example:
				#
				# % sysdef -d | grep "Node '.*,.*'"
				# Node 'SUNW,Ultra-1', unit #-1
				#                 Node 'SUNW,CS4231', unit #-1 (no driver)
				#                 Node 'SUNW,fdtwo', unit #0
				#                 Node 'SUNW,pll', unit #-1 (no driver)
				#                 Node 'SUNW,fas', unit #0
				#                 Node 'SUNW,hme', unit #0
				#                 Node 'SUNW,bpp', unit #-1 (no driver)
				#         Node 'SUNW,UltraSPARC', unit #-1 (no driver)
				#         Node 'SUNW,ffb', unit #0
				my $cpuinfo;
				foreach my $match (/^\tNode '(\w+\,[\w\-\+]+)'/gm)
				{
					if ($host_model =~ /Ultra|Fire/)
					{
						# SUNW is ok here but skip the SUNW,ffb
						next if ($match eq 'SUNW,ffb');
						next if ($match eq 'FJSV,system');
						$cpuinfo = $match;
						last;
					}
					else
					{
						next if ($match =~ /^SUNW/);
						$cpuinfo = $match;
						last;
					}
				}

				if ($cpuinfo)
				{
					($cpu_manufacturer, $cpu_model) = split(',', $cpuinfo);
					last;
				}
			}
			close $sysdeffh;
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				# FIXME: Assuming the manufacturer is the first word is
				# less than ideal
				if (/Processor Name: (\S+)\s(.+)/)
				{
					$cpu_manufacturer = $1;
					$cpu_model = $2;
				}
			}
			close(SP);

			if (!$cpu_manufacturer || !$cpu_model)
			{
				die "Failed to parse CPU info from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_manufacturer returning '$cpu_manufacturer'" if ($debug);
	return $cpu_manufacturer;
}

sub get_cpu_model
{
	if (!$cpu_model)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$cpu_model = $dmidata{'Processor Information'}[0]->{'Family'};
			my $cpu_version = $dmidata{'Processor Information'}[0]->{'Version'};
			# Some processors seem to put the model information into the
			# "Version" field.  So if the "Family" field doesn't have
			# anything interesting and "Version" does then use it.
			if ($cpu_version ne 'Not Specified' &&
				(!$cpu_model ||
					$cpu_model eq 'Other'))
			{
				$cpu_model = $cpu_version;
			}
		}
		elsif ($os eq 'SunOS' || $os eq 'Mac OS X')
		{
			# The CPU model is gathered as a side-effect on these platforms
			get_cpu_manufacturer();
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_model returning '$cpu_model'" if ($debug);
	return $cpu_model;
}

sub get_cpu_speed
{
	if (!$cpu_speed)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$cpu_speed = $dmidata{'Processor Information'}[0]->{'Current Speed'};
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'psrinfo -v'" if ($debug);
			open my $psrinfofh, '-|', 'psrinfo', '-v'
				or die "open psrinfo -v: $!";
			while (<$psrinfofh>)
			{
				if (/operates at (\d+) MHz/)
				{
					$cpu_speed = $1;
					last;
				}
			}
			close $psrinfofh;
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Processor Speed: (.+)/)
				{
					$cpu_speed = $1;
				}
			}
			close(SP);

			if (!$cpu_speed)
			{
				die "Failed to parse CPU speed from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_speed returning '$cpu_speed'" if ($debug);
	return $cpu_speed;
}

# This returns the number of physical CPUs, i.e. the number of CPU dies,
# not the number of cores or other other subsets of a physical CPU.
sub get_cpu_count
{
	if (!$cpu_count)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			my $temp_cpu_count;
			%dmidata = _getdmidata();
			foreach my $socket (@{$dmidata{'Processor Information'}})
			{
				if ($socket->{'Status'} =~ /Populated/)
				{
					$temp_cpu_count++;
				}
			}
			$cpu_count = $temp_cpu_count;
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			# Other than the specific versions of Solaris x86 above where
			# we have a seperate way to query the hardware and get a CPU
			# count we have to rely on the OS having found all of the
			# physical CPUs.  We should continue to add exceptions for
			# platforms where we can more directly query the hardware for
			# a physical CPU count.
			$cpu_count = nVentory::OSInfo::get_os_cpu_count();
		}
		elsif ($os eq 'Mac OS X')
		{
			# It's not clear if system_profiler is reporting the number
			# of physical CPUs or the number seen by the OS.  I'm not
			# sure if there are situations in Mac OS where those two can
			# get out of sync.  As such this is identical to get_os_cpu_count
			# in OSInfo.pm.
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Number Of Processors: (\d+)/)
				{
					$cpu_count = $1;
				}
			}
			close(SP);

			if (!$cpu_count)
			{
				die "Failed to parse CPU count from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_count returning '$cpu_count'" if ($debug);
	return $cpu_count;
}

# This returns a count of CPU cores in the system.  I.e. if a system has
# two dual core CPUs this will return '4'
sub get_cpu_core_count
{
	if (!$cpu_core_count)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/)
		{
			my %cores;
			my $physicalid;
			my $coreid;
			# Each unique physical id and core id pair represents a
			# physical core.  Duplicate phys/core id pairs represent
			# hyper threads or some other form of virtual processor.
			warn "Reading /proc/cpuinfo" if ($debug);
			open my $cpuinfofh, '<', '/proc/cpuinfo' or die "open: $!";
			while (<$cpuinfofh>)
			{
				if (/^processor\s*: (\d+)/)
				{
					undef $physicalid;
					undef $coreid;
				}
				if (/^physical id\s*: (\d+)/)
				{
					$physicalid = $1;
				}
				if (/^core id\s*: (\d+)/)
				{
					$coreid = $1;
				}
				
				if (defined $physicalid && defined $coreid)
				{
					$cores{"$physicalid:$coreid"} = 1;
				}
			}
			close $cpuinfofh;

			# Older combinations of hardware and kernel don't report
			# physical id and core id in /proc/cpuinfo, so we might not
			# have any data in %cores
			if (%cores)
			{
				$cpu_core_count = scalar keys %cores;
			}
			elsif (-x '/usr/sbin/esxcfg-info')
			{
				# But on VMware ESX server the ESX utilities manage to
				# gather the core count from somewhere, so snag the data
				# from there
				warn "Running '/usr/sbin/esxcfg-info'" if ($debug);
				open my $esxcfgfh, '-|', '/usr/sbin/esxcfg-info'
					or die "open /usr/sbin/esxcfg-info: $!";
				while (<$esxcfgfh>)
				{
					if (/Num Cores\.+(\d+)/)
					{
						$cpu_core_count = $1;
					}
				}
				close $esxcfgfh;
			}
		}
		elsif ($os eq 'FreeBSD')
		{
			# FIXME
		}
		elsif ($os eq 'SunOS')
		{
			# FIXME
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Total Number Of Cores: (\d+)/)
				{
					$cpu_core_count = $1;
				}
			}
			close(SP);

			if (!$cpu_core_count)
			{
				die "Failed to parse CPU core count from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_core_count returning '$cpu_core_count'" if ($debug);
	return $cpu_core_count;
}

sub get_cpu_socket_count
{
	if (!$cpu_socket_count)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			my $temp_cpu_socket_count;
			%dmidata = _getdmidata();
			foreach my $socket (@{$dmidata{'Processor Information'}})
			{
				$temp_cpu_socket_count++;
			}
			$cpu_socket_count = $temp_cpu_socket_count;
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			# FIXME
		}
		elsif ($os eq 'Mac OS X')
		{
			# FIXME
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_cpu_socket_count returning '$cpu_socket_count'" if ($debug);
	return $cpu_socket_count;
}

sub get_physical_memory
{
	if (!$physical_memory)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			my $temp_physical_memory;
			my @temp_physical_memory_sizes;
			%dmidata = _getdmidata();
			foreach my $memdevice (@{$dmidata{'Memory Device'}})
			{
				my $size = $memdevice->{'Size'};
				my $form_factor = $memdevice->{'Form Factor'};
				# Some systems report little chunks of memory other than main system
				# memory as Memory Devices, the 'DIMM' as form factor seems to
				# indicate main system memory.
				if ($size ne 'No Module Installed' && $form_factor eq 'DIMM')
				{
					my ($megs, $units) = split(' ', $size);
					die if ($units ne 'MB');
					# We keep both a running total of memory size and an
					# array of the sizes of the individual sticks.
					$temp_physical_memory += $megs;
					push(@temp_physical_memory_sizes, $megs);
				}
			}
			$physical_memory = $temp_physical_memory;
			@physical_memory_sizes = @temp_physical_memory_sizes;
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'prtconf'" if ($debug);
			open my $prtconffh, '-|', 'prtconf'
				or die "open prtconf: $!";
			while (<$prtconffh>)
			{
				if (/Memory size: (\d+)/)
				{
					$physical_memory = $1;
					last;
				}
			}
			close $prtconffh;
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPHardwareDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPHardwareDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Memory: (.+)/)
				{
					$physical_memory = $1;
				}
			}
			close(SP);

			if (!$physical_memory)
			{
				die "Failed to parse physical memory from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_physical_memory returning '$physical_memory'" if ($debug);
	return $physical_memory;
}

sub get_physical_memory_sizes
{
	if (! scalar @physical_memory_sizes)
	{
		my $os = nVentory::OSInfo::getos();
		my @temp_physical_memory_sizes;

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			# The memory sizes are gathered as a side-effect on these platforms
			get_physical_memory();
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			# This is vaguely hacky, but seems better than
			# hardcoding a full path here
			my $myshortpath = 'nVentory/HardwareInfo.pm';
			my $mypath = $INC{$myshortpath};
			my $mydir = $mypath;
			$mydir =~ s/$myshortpath//;
			warn "Running '$mydir/3rdparty/memconf'" if ($debug);
			open my $memconffh, '-|', "$mydir/3rdparty/memconf"
				or die "open $mydir/3rdparty/memconf: $!";
			while (<$memconffh>)
			{
				if (/(\d+)MB/ && !/total/)
				{
					push(@temp_physical_memory_sizes, $1);
				}
			}
			close $memconffh;
		}
		elsif ($os eq 'Mac OS X')
		{
			warn "Running 'system_profiler SPMemoryDataType'" if ($debug);
			open(SP, '-|', 'system_profiler SPMemoryDataType') or die "open: $!";
			while(<SP>)
			{
				if (/Size: (.+)/)
				{
					push(@temp_physical_memory_sizes, $1);
				}
			}
			close(SP);

			if (!@temp_physical_memory_sizes)
			{
				die "Failed to parse memory sizes from system_profiler\n";
			}
		}
		else
		{
			die; # FIXME
		}
		
		if (@temp_physical_memory_sizes)
		{
			@physical_memory_sizes = @temp_physical_memory_sizes;
		}
	}

	warn "get_physical_memory_sizes returning '",
		join(',',@physical_memory_sizes), "'" if ($debug);
	return @physical_memory_sizes;
}

sub get_uniqueid
{
	if (!$uniqueid)
	{
		my $os = nVentory::OSInfo::getos();

		if ($os =~ /Linux/ || $os eq 'FreeBSD')
		{
			%dmidata = _getdmidata();
			$uniqueid = $dmidata{'System Information'}[0]->{'UUID'};
			if (!$uniqueid)
			{
				getnicdata();
				if ($first_nic_hwaddr)
				{
					$uniqueid = $first_nic_hwaddr;
				}
				else
				{
					die "Unable to find a uniqueid";
				}
			}
		}
		elsif ($os eq 'SunOS' &&
			(nVentory::OSInfo::getosarch() eq 'i386' || nVentory::OSInfo::getosarch() eq 'amd64') &&
			nVentory::OSInfo::compare_versions(nVentory::OSInfo::getosversion(), '5.10') >= 0)
		{
			_getsmbiosdata();
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'hostid'" if ($debug);
			my $tempid = `hostid`;
			chomp $tempid;
			$uniqueid = $tempid;
		}
		elsif ($os eq 'Mac OS X')
		{
			# I imagine Mac serial numbers are unique
			$uniqueid = get_host_serial();
		}
		else
		{
			die; # FIXME
		}
	}

	warn "get_uniqueid returning '$uniqueid'" if ($debug);
	return $uniqueid;
}

sub get_power_supply_count
{
	if (!$power_supply_count)
	{
		my $os = nVentory::OSInfo::getos();

		my $temp_power_supply_count;

		# Check for HP's hpasm
		if (-x '/sbin/hpasmcli')
		{
			warn "Running \"/sbin/hpasmcli -s 'show powersupply'\"" if ($debug);
			open(HPASM, '-|', "/sbin/hpasmcli -s 'show powersupply'") or die "open: $!";
			while(<HPASM>)
			{
				if (/Present\s*:\s*Yes/)
				{
					$temp_power_supply_count++;
				}
			}
			close(HPASM);
		}
		# Check for Dell's OMSA
		elsif (-x '/opt/dell/srvadmin/oma/bin/omreport')
		{
			warn "Running '/opt/dell/srvadmin/oma/bin/omreport chassis pwrsupplies'" if ($debug);
			open(OM, '-|', '/opt/dell/srvadmin/oma/bin/omreport chassis pwrsupplies') or die "open: $!";
			while(<OM>)
			{
				if (/^Index/)
				{
					$temp_power_supply_count++;
				}
			}
			close(OM);
		}
		elsif ($os eq 'SunOS')
		{
			warn "Running 'uname -s'" if ($debug);
			my $unamei=`uname -i`;
			chomp $unamei;
			warn "Running '/usr/platform/$unamei/sbin/prtdiag -v'" if ($debug);
			open my $prtdiagfh, '-|', "/usr/platform/$unamei/sbin/prtdiag -v"
				or die "open prtdiag: $!";
			my %sun_power_supplies;
			while (<$prtdiagfh>)
			{
				# prtdiag reports things very differently depending on the
				# hardware model.  So look for and count unique power
				# supply names, this seems to be reliable across models.
				if (/^(PS\d+)\s/)
				{
					$sun_power_supplies{$1} = 1;
				}
			}
			close $prtdiagfh;
			$temp_power_supply_count = scalar keys %sun_power_supplies;
		}
		
		if ($temp_power_supply_count)
		{
			$power_supply_count = $temp_power_supply_count;
		}
	}

	warn "get_power_supply_count returning '$power_supply_count'" if ($debug);
	return $power_supply_count;
}

# Gather a variety of info from dmidecode, which is generally available
# on Linux and FreeBSD
sub _getdmidata
{
	if (!%dmidata)
	{
		# dmidecode will fail if not run as root
		if ($> != 0)
		{
			die "This must be run as root";
		}

		my $look_for_section_name;
		my $dmi_section;
		my %dmi_section_data;
		my $dmi_section_array;
		warn "Running 'dmidecode'" if ($debug);
		open my $dmifh, '-|', 'dmidecode' or die "open dmidecode: $!";
		while (<$dmifh>)
		{
			if (/^Handle/)
			{
				if ($dmi_section && %dmi_section_data)
				{
					# We need to store the data in a new hash so that we
					# can store a reference to that hash in our larger
					# data structure, and reuse %dmi_section_data for the
					# next section.  It is escaping me how to just assign
					# %dmi_section_data a new hash.  The assignment to ()
					# below just clears out the current hash.
					my %tmp = %dmi_section_data;
					push(@{$dmidata{$dmi_section}}, \%tmp)
				}
				# New section of the dmidecode output, reset any state variables
				undef $dmi_section;
				%dmi_section_data = ();
				undef $dmi_section_array;
				# And flag that we should now look for the section name
				$look_for_section_name = 1;
			}
			elsif ($look_for_section_name)
			{
				if (/^\s*DMI type/)
				{
					next;
				}
				elsif (/^\s*(.*)/)
				{
					$dmi_section = $1;
					$look_for_section_name = 0;
				}
			}
			elsif ($dmi_section && /^\s*([^:]+):\s*(\S.*)/)
			{
				$dmi_section_data{$1} = $2;
				undef $dmi_section_array;
			}
			elsif ($dmi_section && /^\s*([^:]+):$/)
			{
				$dmi_section_array = $1;
			}
			elsif ($dmi_section && $dmi_section_array && /^\s*(\S.+)$/)
			{
				push(@{$dmi_section_data{$dmi_section_array}}, $1);
			}
		}
		
		warn "_getdmidata returning ", Dumper(\%dmidata) if ($debug);
	}

	return %dmidata;
}

# Gather a variety of info from smbios, which is available on Solaris x86
# starting with Solaris 10
sub _getsmbiosdata
{
	my $temp_cpu_manufacturer;
	my $temp_cpu_model;
	my $temp_cpu_speed;
	my $temp_cpu_socket_count;
	my $temp_cpu_count;
	my $temp_physical_memory;
	my @temp_physical_memory_sizes;

	my $look_for_section_name;
	my $smbios_section;
	warn "Running 'smbios'" if ($debug);
	open my $smbiosfh, '-|', 'smbios' or die "open smbios: $!";
	while (<$smbiosfh>)
	{
		if (/^ID\s+SIZE\s+TYPE/)
		{
			# New section of the smbios output, reset any state variables
			undef $smbios_section;
			# And flag that we should now look for the section name
			$look_for_section_name = 1;
		}
		elsif ($look_for_section_name)
		{
			if (/^\d+\s+\d+\s+SMB_TYPE_(\S+)/)
			{
				$smbios_section = $1;
				$look_for_section_name = 0;
			}
		}
		elsif ($smbios_section && $smbios_section eq 'SYSTEM')
		{
			if (/^\s+Manufacturer: (.+\b)/)
			{
				$host_manufacturer = $1;
			}
			elsif (/^\s+Product: (.+\b)/)
			{
				$host_model = $1;
			}
			elsif (/^\s+Serial Number: (.+\b)/)
			{
				$host_serial = $1;
			}
			elsif (/^\s+UUID: (.+\b)/)
			{
				$uniqueid = $1;
			}
		}
		elsif ($smbios_section && $smbios_section eq 'PROCESSOR')
		{
			if (/^\s+Manufacturer: (.+\b)/)
			{
				$temp_cpu_manufacturer = $1;
			}
			elsif (/^\s+Family: \d+ \((.+\b)\)/)
			{
				$temp_cpu_model = $1;
			}
			elsif (/^\s+Current Speed: (.+\b)/)
			{
				$temp_cpu_speed = $1;
			}
			elsif (/^\s+Socket Status: (.+\b)/)
			{
				my $status = $1;

				$temp_cpu_socket_count++;

				if ($status =~ /Populated/)
				{
					$temp_cpu_count++;

					$cpu_manufacturer =
						$temp_cpu_manufacturer;
					undef $temp_cpu_manufacturer;
					$cpu_model = $temp_cpu_model;
					undef $temp_cpu_model;
					$cpu_speed = $temp_cpu_speed;
					undef $temp_cpu_speed;
				}
			}
		}
		elsif ($smbios_section && $smbios_section eq 'MEMDEVICE')
		{
			if (/^\s+Size: (.+\b)/)
			{
				my $size = $1;
				if ($size ne 'Not Populated')
				{
					my ($bytes, $units) = split(' ', $size);
					die if ($units ne 'bytes');
					my $megs = int($bytes / 1024 / 1024);
					# We keep both a running total of memory size and an
					# array of the sizes of the individual sticks.
					$temp_physical_memory += $megs;
					push(@temp_physical_memory_sizes, $megs);
				}
			}
		}
	}
	close $smbiosfh;

	# For each of these counter/collector-type variables we use a temporary
	# variable to collect the data and then update the real variable in
	# an atomic operation, so that there isn't a period where the real
	# variable has only partial data.
	$cpu_socket_count = $temp_cpu_socket_count;
	$cpu_count = $temp_cpu_count;
	$physical_memory = $temp_physical_memory;
	@physical_memory_sizes = @temp_physical_memory_sizes;
}

# The following info is gathered for each network interface
# - Hardware address
# - IP addresses (both IPv4 and IPv6)
# - Speed
# - Duplex
# - Link
sub getnicdata
{
	if (!%nicdata)
	{
		my $nic;

		my $os = nVentory::OSInfo::getos();

		warn "Running 'ifconfig -a'" if ($debug);
		open my $ifconfigfh, '-|', 'ifconfig', '-a'
			or die "open ifconfig -a: $!";
		while (<$ifconfigfh>)
		{
			# Look for the line that indicates a new interface.  FreeBSD and
			# Solaris put a colon after the interface name.
			# Variants:
			# eth0
			# lo         (Loopback on Linux)
			# eth0.90    (802.1q interface on Linux)
			# eth0.90:0  (Virtual interface on a 802.1q interface)
			# eth0.100:  (Virtual interface that was cut off for being too
			# long)
			# bge0:      (FreeBSD)
			# eri0:      (Solaris)
			# lo0:       (Loopback on FreeBSD or Solaris)
			if (/^(\w+\S+)/)
			{
				$nic = $1;

				# Strip off the FreeBSD/Solaris colon
				# We can't strip all trailing colons, otherwise we'd
				# mix up eth0.100 and eth0.100: (where the later is
				# probably eth0.100:0 but got cut off by ifconfig)
				if ($os eq 'FreeBSD' || $os eq 'SunOS' ||
					$os eq 'Darwin' || $os eq 'Mac OS X')
				{
					$nic =~ s/:$//;
				}

				# The line indicating whether the interface is up or not
				# is scattered in different places depending on the OS.
				# Assume it is down unless we find that it is up in the
				# code below.
				$nicdata{$nic}->{up} = 0;
			}

			if (/(?:HWaddr|ether) ([\da-fA-F:]+)/)
			{
				$nicdata{$nic}->{hardware_address} = $1;

				if (/ether/)
				{
					$nicdata{$nic}->{interface_type} = 'Ethernet';
				}

				# Save the first NIC hardware address for use as the
				# unique ID for the host if we are unable to find a
				# better unique ID through other means.
				if (! $first_nic_hwaddr)
				{
					$first_nic_hwaddr = $nicdata{$nic}->{hardware_address};
				}
			}

			if (/(?:inet addr:|inet )([\d\.]+)/)
			{
				my $ipaddr = $1;

				# Linux:    Mask:255.255.240.0
				# BSD:      netmask 0xffffff00
				# Solaris:  netmask ffffff00
				my $netmask;
				if (/(?:Mask:|netmask )(?:0x)?([a-f0-9]{8}|[\d\.]+)/)
				{
					my $tempmask = $1;

					# Standardize netmask to dotted-quad format
					if ($tempmask =~ /^[a-f0-9]{8}$/)
					{
						my @parts = unpack 'A2A2A2A2', $tempmask;
						my @hexparts;
						foreach my $part (@parts)
						{
							push(@hexparts, hex $part);
						}

						$tempmask = join('.', @hexparts);
					}
					
					$netmask = $tempmask;
				}

				# Linux:    Bcast:64.182.127.255
				# BSD:      broadcast 66.163.167.255
				# Solaris:  broadcast 66.163.167.255
				my $broadcast;
				if (/(?:Bcast:|broadcast )([\d\.]+)/)
				{
					$broadcast = $1;
				}

				push(@{$nicdata{$nic}->{ip_addresses}},
					{
						'address_type' => 'ipv4',
						'address' => $ipaddr,
						'netmask' => $netmask,
						'broadcast' => $broadcast,
					});
			}
			if (/(?:inet6 addr:|inet6) ([\da-fA-F:]+)/)
			{
				push(@{$nicdata{$nic}->{ip_addresses}},
					{
						'address_type' => 'ipv6',
						'address' => $1,
					});
			}
			if (/media: (\w+ )?autoselect .(\d+)baseTX .(\w+)-duplex/)
			{
				$nicdata{$nic}->{autonegotiate} = 1;
				if ($1)
				{
					$nicdata{$nic}->{interface_type} = $1;
					$nicdata{$nic}->{speed} = $2;
					if ($3 eq 'full')
					{
						$nicdata{$nic}->{full_duplex} = 1;
					}
					else
					{
						$nicdata{$nic}->{full_duplex} = 0;
					}
				}
				else # Mac OS X
				{
					# FIXME:
					# For Ethernet we captured the type earlier when we
					# picked up the MAC address.  For others we should run
					# 'system_profiler SPNetworkDataType' to find out
					#$nicdata{$nic}->{type} = '';
					$nicdata{$nic}->{speed} = $2;
					if ($3 eq 'full')
					{
						$nicdata{$nic}->{full_duplex} = 1;
					}
					else
					{
						$nicdata{$nic}->{full_duplex} = 0;
					}
				}
			}
			elsif (/media: (\w+) (\d+)baseTX .(\w+)-duplex/)
			{
				$nicdata{$nic}->{autonegotiate} = 0;
				$nicdata{$nic}->{interface_type} = $1;
				$nicdata{$nic}->{speed} = $2;
				if ($3 eq 'full')
				{
					$nicdata{$nic}->{full_duplex} = 1;
				}
				else
				{
					$nicdata{$nic}->{full_duplex} = 0;
				}
			}
			if (/supported media: (.*)/ &&
				$nicdata{$nic}->{interface_type} &&
				$nicdata{$nic}->{interface_type} eq 'Ethernet')
			{
				my $sm = $1;
				# Look for something like 10baseT, 100baseTX, etc.
				# That seems to be the best indication on Mac OS X
				# that an Ethernet interface is a physical interface.
				if ($sm =~ /0base/)
				{
					$nicdata{$nic}->{physical} = 1;
				}
				else
				{
					$nicdata{$nic}->{physical} = 0;
				}
			}
			if (/encap:(\S+)/)
			{
				$nicdata{$nic}->{interface_type} = $1;
			}
			if (/^\s*RX .* errors:(\d+)/)
			{
				$nicdata{$nic}->{rxerrs} = $1;
			}
			if (/^\s*TX .* errors:(\d+)/)
			{
				$nicdata{$nic}->{txerrs} = $1;
			}
			if (/status: (\w+)/)
			{
				if ($1 eq 'active')
				{
					$nicdata{$nic}->{link} = 1;
				}
				else
				{
					$nicdata{$nic}->{link} = 0;
				}
			}
			if (/^\s+UP / || /flags=.*UP,/)
			{
				$nicdata{$nic}->{up} = 1;
			}
		}
		close $ifconfigfh;

		# Gather additional Linux NIC info from various sources
		if ($os =~ /Linux/)
		{
			foreach my $nic (keys %nicdata)
			{
				# ethtool only applies to Ethernet interfaces
				next if ($nicdata{$nic}->{interface_type} ne 'Ethernet');
				# Don't bother for virtual interfaces
				next if ($nic =~ /:/);

				# Run ethtool to grab the speed, duplex, link and
				# autoneg status
				# 
				# Use open3 so that we can capture and ignore stderr
				# from ethtool.  ethtool frequently spits an error to
				# stderr when run against interfaces that are down.
				# 
				# Bah, can't use scalar filehandles.  Blech.
				# http://rt.perl.org/rt3/Public/Bug/Display.html?id=31738
				warn "Running 'ethtool $nic'" if ($debug);
				my $pid = open3(\*IN, \*OUT, \*ERR,
					'ethtool', $nic)
					or die "open ethtool: $!";
				close IN;
				while (<OUT>)
				{
					if (/Speed: (\d+)Mb/)
					{
						$nicdata{$nic}->{speed} = $1;
					}
					elsif (/Duplex: (\w+)/)
					{
						if (lc $1 eq 'full')
						{
							$nicdata{$nic}->{full_duplex} = 1;
						}
						else
						{
							$nicdata{$nic}->{full_duplex} = 0;
						}
					}
					elsif (/Advertised auto-negotiation: (.*)/)
					{
						if ($1 eq 'Yes')
						{
							$nicdata{$nic}->{autonegotiate} = 1;
						}
						else
						{
							$nicdata{$nic}->{autonegotiate} = 0;
						}
					}
					elsif (/Link detected: (\w+)/)
					{
						if ($1 eq 'yes')
						{
							$nicdata{$nic}->{link} = 1;
						}
						else
						{
							$nicdata{$nic}->{link} = 0;
						}
					}
				}
				close OUT;
				close ERR;
				waitpid $pid, 0;
			}
		}
		# Gather Solaris NIC speed and duplex
		if ($os eq 'SunOS')
		{
			# This is vaguely hacky, but seems better than
			# hardcoding a full path here
			my $myshortpath = 'nVentory/HardwareInfo.pm';
			my $mypath = $INC{$myshortpath};
			my $mydir = $mypath;
			$mydir =~ s/$myshortpath//;
			warn "Running '$mydir/3rdparty/checkcable'" if ($debug);
			open my $checkfh, '-|', "$mydir/3rdparty/checkcable"
				or die "open $mydir/3rdparty/checkcable: $!";
			while (<$checkfh>)
			{
				# Skip the header line
				next if (/^Interface/);

				my ($nic, $link, $duplex, $speed, $autoneg) = split;

				$nicdata{$nic}->{speed} = $speed;

				if ($duplex eq 'FULL')
				{
					$nicdata{$nic}->{full_duplex} = 1;
				}
				else
				{
					$nicdata{$nic}->{full_duplex} = 0;
				}

				if ($link eq 'UP')
				{
					$nicdata{$nic}->{link} = 1;
				}
				else
				{
					$nicdata{$nic}->{link} = 0;
				}

				if ($autoneg eq 'ON')
				{
					$nicdata{$nic}->{autonegotiate} = 1;
				}
				else
				{
					$nicdata{$nic}->{autonegotiate} = 0;
				}
			}
			close $checkfh;
		}
		if ($os eq 'FreeBSD' || $os eq 'SunOS' ||
			$os eq 'Darwin' || $os eq 'Mac OS X')
		{
			# Run netstat to grab interface errors
			warn "Running 'netstat -in'" if ($debug);
			open my $netstatfh, '-|', 'netstat', '-in'
				or die "open netstat -in: $!";
			while (<$netstatfh>)
			{
				# Skip the header line
				next if (/^Name/);
				# Skip blank lines
				next if (/^\s*$/);

				# On BSD we only want the "Link" entry for each
				# interface
				next if (($os eq 'FreeBSD' || $os eq 'Darwin' ||
						  $os eq 'Mac OS X') && !/Link/);

				my ($nic, $mtu, $network, $addr, $rxpkts, $rxerrs,
					$txpkts, $txerrs, $collision) = split(' ');

				# In some cases on BSD the Address column will be
				# empty.  In that case the rxpkts value will end up in
				# $addr.  We can detect that if $addr is a pure number.
				if ($addr =~ /^\d+$/)
				{
					my ($nic, $mtu, $network, $rxpkts, $rxerrs,
						$txpkts, $txerrs, $collision) = split(' ');
				}

				if ($os eq 'Darwin' || $os eq 'Mac OS X')
				{
					# Some interfaces are listed with a * after their
					# name.  The netstat man page doesn't indicate what
					# that means.
					$nic =~ s/\*$//;
				}

				$nicdata{$nic}->{rxerrs} = $rxerrs;
				$nicdata{$nic}->{txerrs} = $txerrs;
			}
			close $netstatfh;
		}

		# On Linux and Solaris the best indication of whether an
		# Ethernet interface is physical or not seems to be whether
		# ifconfig reports interface statistics (TX/RX bytes,
		# errors, etc.)  On Linux this seems to correlate with whether
		# or not the interface is represented in /proc/net/dev.
		if ($os eq 'Linux' || $os eq 'SunOS')
		{
			foreach my $nic (keys %nicdata)
			{
				if ($nicdata{$nic}->{interface_type} &&
					$nicdata{$nic}->{interface_type} eq 'Ethernet')
				{
					if (exists $nicdata{$nic}->{rxerrs})
					{
						$nicdata{$nic}->{physical} = 1;
					}
					else
					{
						$nicdata{$nic}->{physical} = 0;
					}
				}
			}
		}
	}

	warn "get_nicdata returning ", Dumper(\%nicdata) if ($debug);
	return %nicdata;
}

sub setdebug
{
	my ($newdebug) = @_;
	$debug = $newdebug;
	nVentory::OSInfo::setdebug($newdebug);
}

1;

