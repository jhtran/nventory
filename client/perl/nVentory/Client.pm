package nVentory::Client;

use strict;
use warnings;
use nVentory::HardwareInfo;
use nVentory::OSInfo;
use LWP::UserAgent;
use File::stat;
use URI;
use HTTP::Cookies;
use HTTP::Request::Common;  # GET, PUT, POST
use HTTP::Status;          # RC_* constants
use File::stat;            # Improved stat
use XML::LibXML;

my $debug;
my $dryrun;

my $SERVER = 'http://nventory';
my $PROXY_SERVER;
#my $PROXY_SERVER = 'https://proxy.example.local:8080';

########################################################################################
## specify which external modules based on lshw's controller 'product' string ##
## Note: should look into Module::Load or Module::Plugin or UNIVERSAL::require ##
########################################################################################
use nVentory::CompaqSmartArray;

# dir location where xen img files held if this is xen host
my $XEN_IMGDIR = '/home/xen/disks';
# If user manually specifies server other than the default
sub setserver
{
	$SERVER = 'http://' . $_[0];
	warn "** nVentory server: $SERVER **\n";
}
CONFIGFILE: foreach my $configfile ('/etc/nventory.conf', $ENV{HOME}.'/.nventory.conf')
{
	if (-f $configfile)
	{
		open my $configfh, '<', $configfile or next CONFIGFILE;
		while (<$configfh>)
		{
			next if (/^\s*$/);  # Skip blank lines
			next if (/^\s*#/);  # Skip comments
			chomp;
			my ($key, $value) = split /\s*=\s*/, $_, 2;
			if ($key eq 'server')
			{
				$SERVER = $value;

				# Warn the user, as this could potentially be confusing
				# if they don't realize there's a config file lying
				# around
				#warn "Using server $SERVER from $configfile\n";
			}
			elsif ($key eq 'proxy_server')
			{
				$PROXY_SERVER = $value;
				#warn "Using proxy server $PROXY_SERVER from $configfile\n" if $debug;
			}
			elsif ($key eq 'ca_file' && -f $value)
			{
				# This currently executes before anyone could call setdebug,
				# so the debug message is never printed.
				#warn "Using CA file $value from $configfile\n" if ($debug);
				$ENV{HTTPS_CA_FILE} = $value;
			}
			elsif ($key eq 'ca_path' && -d $value)
			{
				# This currently executes before anyone could call setdebug,
				# so the debug message is never printed.
				#warn "Using CA directory $value from $configfile\n" if ($debug);
				$ENV{HTTPS_CA_DIR} = $value;
			}
		}
		close $configfh;
	}
}

my $_read_ua;
my $_write_ua;
sub _get_ua
{
	my ($login, $password_callback) = @_;

	if ($login)
	{
		return $_write_ua if ($_write_ua);
	}
	else
	{
		return $_read_ua if ($_read_ua);
	}

	my $cookiefile;
	my $password;
	if ($login && $login eq 'autoreg')
	{
		$cookiefile = '/root/.nventory_cookie_autoreg';
		$password = 'mypassword';
		if (! -d '/root')
		{
			mkdir '/root' or die "mkdir: $!";
		}
	}
	else
	{
		$cookiefile = $ENV{HOME} . '/.nventory_cookie';
	}

	# Create the cookie file if it doesn't already exist
	if (! -f $cookiefile)
	{
		warn "Creating $cookiefile\n";
		open my $cookiefh, '>', $cookiefile or die "open: $!";
		close $cookiefh;
	}
	# Ensure the permissions on the cookie file are appropriate,
	# as it will contain a session key that could be used by others
	# to impersonate this user to the server.
	my $st = stat $cookiefile or die "stat: $!";
	if ($st->mode & 07177)
	{
		warn "Correcting permissions on $cookiefile\n";
		chmod $st->mode & 0600, $cookiefile or die "chmod: $!";
	}

	warn "Using cookies from $cookiefile\n" if ($debug);
	my $cookie_jar = HTTP::Cookies->new(
		file => $cookiefile,
		autosave => 1,
		ignore_discard => 1,
	);

	my $ua = LWP::UserAgent->new;
	$ua->cookie_jar($cookie_jar);

	if ($login)
	{
		# User wants to be able to write to the server

		# First check if any existing session id works by sending
		# an empty POST to the accounts controller.  We will get
		# back a 302 redirect if we need to authenticate.  There's
		# nothing special about accounts, we could use any controller,
		# accounts just seemed appropriate.
		# We include some bogus content in the post to work around
		# a bug in HTTP::Request::Common::POST prior to version 5.72 of
		# libwww-perl that wouldn't set a Content-Length header when the
		# content is empty.  RHEL 3 includes a broken version.

		## proxing - this format doesn't work for some reason
		#$ua->proxy('https', $PROXY_SERVER);
		if ($PROXY_SERVER) { $ENV{HTTPS_PROXY} = $PROXY_SERVER; }

		my $response = $ua->request(POST "$SERVER/accounts.xml", { 'foo' => 'bar' });
		# NON-autoreg user logins should be redirected to SSO naturally.
		if ( ($response->is_redirect) && ( $login ne 'autoreg' ) )
		{
			# nventory nginx will redirect all NONfqdn (https://nventory) to FQDN.  This logic will handle that, as POST will
			# not follow redirect.  LWP::UserAgent claims the requests_redirectable would work w/ POST but can't get to work
			while (($response->is_redirect) && ($response->header('location') !~ /^https:\/\/sso.*\/login\?url/)) { 
				my $location = $response->header('location');
				$response = $ua->request(POST $location, { 'foo' => 'bar' });
			}
			if (($response->is_redirect) && ($response->header('location') =~ /^https:\/\/(sso.*)\/login\?url/)) {
				warn "POST to $SERVER/accounts.xml was redirected, authenticating to SSO\n" if ($debug);
				my $SSO_SERVER=$1;
				warn "SSO_SERVER: $SSO_SERVER\n" if ($debug);
	                        # Logins need to go to HTTPS
	                        print "Login: $login\n";
	                        my $url = URI->new("https://$SSO_SERVER/session");
	                        $url->scheme('https');
	                        $password = &$password_callback() if (!$password);
				print "Authenticating to $url...\n";
	                        $response = $ua->request(POST $url, {'login' => $login, 'password' => $password});
	
	                        if ($response->is_success == 1 )
	                        {
	                                if ($response->content =~ /Can't connect .* Invalid argument/)
	                                {
	                                        warn "Looks like you're missing Crypt::SSLeay"
	                                }
	                                die "Authentication failed:\n", $response->content, "\n";
				} else {
					print "Authentication Successful\n";
	                        }
			}
                        if (($response->is_redirect) && ($response->header('location') =~ /^(http|https):\/\/(sso.*)\/session\/tokens/)) {
				my $location = URI->new($response->header('location'));
				# SSO tries to redirect u multiple times to find the right domain but we only need the first redirect and then grab cookie
				$ua->max_redirect(2);
				$ua->timeout(10);
				$response = $ua->get($location);
			}
			$ua->max_redirect(7);
		}
		# Autoreg user should NOT be redirected to SSO even if it wants to.  Autoreg auths to uri '/login/login' (which will allow LOCAL and LDAP account logins)
		if ( ($response->is_redirect) && ( $login eq 'autoreg' ) )
		{
			my $location;
			# if it's a redirect yet not sso url, then we should follow the redirect and keep trying the post
			while (($response->is_redirect) && ($response->header('location') !~ /^https:\/\/sso.*\/login\?url/)) { 
				$location = URI->new($response->header('location'));
				$response = $ua->request(POST $location, { 'foo' => 'bar' });
			}
			# if the redirect is a sso url, then we know we need to authenticate by bypassing sso via the url path '/login/login'
			if (($response->is_redirect) && ($response->header('location') =~ /^https:\/\/(sso.*)\/login\?url/)) {
				warn "POST to $SERVER/accounts.xml ( ** for user 'autoreg' ** ) was redirected, authenticating to local login path: '/login/login'\n" if ($debug);
                                my $authbase;
                                if ($location)
                                {
                                        $authbase = 'https://' . $location->authority;
                                }
                                else
                                {
                                        $authbase = "$SERVER";
                                }
                                my $url = URI->new("$authbase/login/login");
	                        $url->scheme('https');
	                        $password = &$password_callback() if (!$password);
	                        $response = $ua->request(POST $url, {'login' => $login, 'password' => $password});
				unless (($response->is_redirect) && ($response->header('location') !~ /^https:\/\/(sso.*)\/login\?url/)) {
					die "\n!!! Authentication failed !!!!\n\n" . $response->message . "\n";
				}
			}
		}

		# Cache UA
		$_write_ua = $ua;
		$_read_ua = $ua;
	}
	else
	{
		# Cache UA
		$_read_ua = $ua;
	}

	return $ua;
}

# Sets flag for search results of deleted (hidden & reserved) objects 
my $delete;
sub setdelete
{
        ($delete) = @_;
	warn "** You have requested to delete object(s) **\n";
}

sub _xml_to_perl
{
	my ($xmlnode) = @_;
	
	# The server includes a hint as to the type of data structure
	# in the XML
	if ($xmlnode->getAttribute('type') &&
		$xmlnode->getAttribute('type') eq 'array')
	{
		my @array = ();
		foreach my $child ($xmlnode->findnodes('*'))
		{
			push @array, _xml_to_perl($child);
		}
		return \@array;
	}
	elsif ($xmlnode->childNodes->size <= 1)
	{
		return $xmlnode->string_value;
	}
	else
	{
		my %hash = ();
		foreach my $child ($xmlnode->findnodes('*'))
		{
			my $field = $child->nodeName;
			$hash{$field} = _xml_to_perl($child);
		}
		return \%hash;
	}
}

sub get_objects
{
	# PS-544 include legacy backward support for long list of params
	my ($objecttype, %get, %exactget, %regexget, %excludeget, %andget, $includesref, $login);
	if (ref($_[0]) eq 'HASH')
	{
		die "Syntax error" if ( scalar @_ > 1 );
		my %getdata = %{$_[0]};
		die "Syntax error" unless $getdata{'objecttype'};
		$objecttype = $getdata{'objecttype'};
		%get = %{$getdata{'get'}} if defined($getdata{'get'});
		%exactget = %{$getdata{'exactget'}} if defined($getdata{'exactget'});
		%regexget = %{$getdata{'regexget'}} if defined($getdata{'regexget'});
		%excludeget = %{$getdata{'exclude'}} if defined($getdata{'exclude'});
		%andget = %{$getdata{'and'}} if defined($getdata{'and'});
		$includesref = $getdata{'includes'} if defined($getdata{'includes'});
		$login = $getdata{'login'} if defined($getdata{'login'});
	} else {
		my ($getref, $exactgetref, $regexgetref, $excluderef, $andref);
		($objecttype, $getref, $exactgetref, $regexgetref, $excluderef, $andref, $includesref, $login) = @_;
		%get = %$getref;
		%exactget = %$exactgetref;
	        %regexget = %$regexgetref;
	        %excludeget = %$excluderef;
	        %andget = %$andref;
	}
	die "Syntax error" if ((!scalar %exactget) && (!scalar %get) && (!scalar %regexget));
        
	#
	# Package up the search parameters in the format the server expects
	#
	
	my %metaget;
	while (my ($key, $values) = each %get)
	{
		if (scalar @$values > 1)
		{
			$metaget{$key . '[]'} = $values;
		}
		else
		{
			# This isn't strictly necessary, specifying a single value via
			# 'key[]=[value]' would work fine, but this makes for a cleaner URL
			# and slightly reduced processing on the backend
			my $value = @{$values}[0];
			$metaget{$key} = $value;
		}
	}
	while (my ($key, $values) = each %exactget)
	{
		if (scalar @$values > 1)
		{
			$metaget{'exact_' . $key . '[]'} = $values;
		}
		else
		{
			# This isn't strictly necessary, specifying a single value via
			# 'key[]=[value]' would work fine, but this makes for a cleaner URL
			# and slightly reduced processing on the backend
			my $value = @{$values}[0];
			$metaget{'exact_' . $key} = $value;
		}
	}
	while (my ($key, $values) = each %regexget)
	{
		if (scalar @$values > 1)
		{
			$metaget{'regex_' . $key . '[]'} = $values;
		}
		else
		{
			# This isn't strictly necessary, specifying a single value via
			# 'key[]=[value]' would work fine, but this makes for a cleaner URL
			# and slightly reduced processing on the backend
			my $value = @{$values}[0];
			$metaget{'regex_' . $key} = $value;
		}
	}
	while (my ($key, $values) = each %excludeget)
	{
		if (scalar @$values > 1)
		{
			$metaget{'exclude_' . $key . '[]'} = $values;
		}
		else
		{
			# This isn't strictly necessary, specifying a single value via
			# 'key[]=[value]' would work fine, but this makes for a cleaner URL
			# and slightly reduced processing on the backend
			my $value = @{$values}[0];
			$metaget{'exclude_' . $key} = $value;
		}
	}
	while (my ($key, $values) = each %andget)
	{
		if (scalar @$values > 1)
		{
			$metaget{'and_' . $key . '[]'} = $values;
		}
		else
		{
			# This isn't strictly necessary, specifying a single value via
			# 'key[]=[value]' would work fine, but this makes for a cleaner URL
			# and slightly reduced processing on the backend
			my $value = @{$values}[0];
			$metaget{'and_' . $key} = $value;
		}
	}

	if ($includesref)
	{
		# includes = ['status', 'rack:datacenter']
		# maps to
		# include[status]=&include[rack]=datacenter
		foreach my $inc (@$includesref)
		{
			if ($inc =~ /:/)
			{
				my $incstring = '';
				my @incparts = split(/:/, $inc);
				my $lastpart = pop(@incparts);
				$incstring = 'include';
				foreach my $part (@incparts)
				{
					$incstring .= "[$part]";
				}
				$metaget{$incstring} = $lastpart;
			}
			else
			{
				$metaget{"include[$inc]"} = '';
			}
		}
	}

	#
	# Send the query to the server
	#
	my $url = URI->new("$SERVER/$objecttype.xml");
	$url->query_form(%metaget);
	my $ua = _get_ua($login);
        die "Authentication failed" unless $ua;
	warn "GET URL: $url\n" if ($debug);
	my $response = $ua->get($url);
	if (!$response->is_success)
	{
		die $response->status_line;
	}

	#
	# Parse the XML data from the server
	# This tries to render the XML into the best possible representation
	# as a Perl hash.  It may need to evolve over time.
	#
	
	my $parser = XML::LibXML->new();
	print $response->content if ($debug);
	my $doc = $parser->parse_string($response->content);
	my %results;
	foreach my $xmlnode ($doc->findnodes("/$objecttype/*"))
	{
		my $dataref = _xml_to_perl($xmlnode);
		my %data = %$dataref;
		my $name = $data{name} || $data{id};
		$results{$name} = \%data;
	}

	if ($debug)
	{
		use Data::Dumper;
		print Dumper(\%results);
	}
	return %results;
}

sub get_field_names
{
	my ($objecttype) = @_;
	my $url = URI->new("$SERVER/$objecttype/field_names.xml");
	my $ua = _get_ua();
	warn "GET URL: $url\n" if ($debug);
	my $response = $ua->get($url);
	if (!$response->is_success)
	{
		die $response->status_line;
	}

	my $parser = XML::LibXML->new();
	print $response->content if ($debug);
	my $doc = $parser->parse_string($response->content);
	my @field_names;
	foreach my $xmlnode ($doc->findnodes("/field_names/*"))
	{
		push @field_names, $xmlnode->string_value;
	}
	return @field_names;
}

sub get_expanded_nodegroup
{
	my ($nodegroup) = @_;

        my %getdata;
        $getdata{'objecttype'} = 'node_groups';
        $getdata{'exactget'} ={ 'name' => [$nodegroup] };
        $getdata{'includes'} = ['nodes', 'child_groups'];
        my %results = get_objects(\%getdata);
	my %nodes;
	foreach my $node (@{$results{$nodegroup}->{nodes}})
	{
		$nodes{$node->{name}} = 1;
	}
	foreach my $child_group (@{$results{$nodegroup}->{child_groups}})
	{
		foreach my $child_group_node (get_expanded_nodegroup($child_group->{name}))
		{
			$nodes{$child_group_node} = 1;
		}
	}
	return sort keys %nodes;
}

# FIXME: Would be really nice to figure out a way to use the Rails inflector
sub singularize
{
	my ($word) = @_;
	my $singular;
	# statuses -> status
	# ip_addresses -> ip_address
	if ($word =~ /(.*s)es$/)
	{
		$singular = $1;
	}
	# nodes -> node
	# vips -> vip
	elsif ($word =~ /(.*)s$/)
	{
		$singular = $1;
	}
	else
	{
		$singular = $word;
	}
	return $singular;
}

# The results argument can be a reference to a hash returned by a
# call to get_objects, in which case the data will be PUT to each object
# there, thus updating them.  Or it can be 'undef', in which case the
# data will be POSTed to create a new entry.
sub set_objects
{
	my ($objecttypes, $resultsref, $dataref, $login, $password_callback) = @_;
	my %results;
	if ($resultsref)
	{
		%results = %$resultsref;
	}
	my %data = %$dataref;
	
	# Convert any keys which don't already specify a model
	# from 'foo' to 'objecttype[foo]'
	my %cleandata;
	my $objecttype = singularize($objecttypes);

	if ($dryrun) {
        	use Data::Dumper;
        	print Dumper(\%data);
        	exit;
        }

	while (my ($key, $value) = each %data)
	{
		if ($key !~ /\[.+\]/)
		{
			$cleandata{$objecttype."[$key]"} = $value;
		}
		else
		{
			$cleandata{$key} = $value;
		}
	}

	if ($debug)
	{
		use Data::Dumper;
		print Dumper(\%cleandata);
	}

	my $response;
	if (%results)
	{
		foreach my $result (keys %results)
		{
			my $id = $results{$result}->{id};

			# PUT to update an existing object
			if ($id && $delete) 
                        {
				my $ua = _get_ua($login, $password_callback);
				warn "DELETE to URL: $SERVER/$objecttypes/$id.xml\n" if ($debug);
				$response = $ua->request(POST "$SERVER/$objecttypes/$id.xml", [ _method => 'delete' ]);
                                while ($response->is_redirect) {
                                        my $newlo = $response->header('location');
					print "Redirected attempt to post: $newlo\n" if $debug;
					$response = $ua->request(POST $newlo, [ _method => 'delete' ]);
                                }
                        }
                        elsif ($id && !$delete)
			{
				# HTTP::Request::Common doesn't support taking form data
				# and encoding it into the content field for PUT requests,
				# only POST.  So fake it out by asking it for a POST request
				# and then converting that to PUT.
				my $request = POST("$SERVER/$objecttypes/$id.xml", \%cleandata);
				$request->method('PUT');
				my $ua = _get_ua($login, $password_callback);
				warn "PUT to URL: $SERVER/$objecttypes/$id.xml\n" if ($debug);
				$response = $ua->request($request);
				# due to nginx redirect from shortname (http://nventory) to fqdn, needs to handle POST redirects
				    # lwp::useragent has a 'requests_redirectable' allowable for POSTS but can't get it working
				while ($response->is_redirect) { 
					my $newlo = $response->header('location');
					$request = POST($newlo, \%cleandata);
					$request->method('PUT');
					warn "PUT to URL: $newlo" if ($debug);
					$response = $ua->request($request);
				}
                                my (@output) = split("\n",$response->content);
				foreach my $line (@output) { 
 					if ($line !~ /</) { print "** INFO **: $line\n"; }
                                }
				print "Command completed successfully\n";
			}
			else
			{
				warn "set_objects passed a bogus \%results hash, $result has no id field\n";
			}

			# FIXME: Aborting partway through a multi-node action is probably
			# not ideal behavior
			if (!$response->is_success)
			{
				warn "Response: ", $response->status_line, "\n";
				warn "Response content:\n", $response->content, "\n";
				return $response;
			}
		}
	}
	else
	{
		# POST to create a new node
		my $ua = _get_ua($login, $password_callback);
		warn "POST to URL: $SERVER/$objecttypes.xml\n" if ($debug);
		$response = $ua->request(POST "$SERVER/$objecttypes.xml", \%cleandata);
		while ($response->is_redirect) { 
			my $newlo = $response->header('location');
			$response = $ua->request(POST $newlo, \%cleandata);
		}
		if ($response->code != RC_CREATED)
		{
			warn "Response: ", $response->status_line, "\n";
			warn "Response content:\n", $response->content, "\n";
			return $response;
		}
	}
        return $response;
}

sub register
{
	my %params;
	%params = %{$_[0]} if $_[0];
	my %data;

	#
	# Gather software-related information
	#
        ## NIC ##
	my %nicdata = nVentory::HardwareInfo::getnicdata(\%params);
	my $niccounter = 0;
	while (my ($nic, $valueref) = each %nicdata)
	{
		$data{"network_interfaces[$niccounter][name]"} = $nic;
		while (my ($field, $value) = each %$valueref)
		{
			if ($field eq 'ip_addresses')
			{
				my $ipcounter = 0;
				foreach my $ipref (@$value)
				{
					while (my ($ipfield, $ipvalue) = each %$ipref)
					{
						if ($ipfield eq 'network_ports')
						{
							my $portcounter = 0;
							while (my ($protocol, $portvalue) = each %$ipvalue)
							{
								while (my ($port, $app) = each %$portvalue)
								{
									$data{"network_interfaces[$niccounter][ip_addresses][$ipcounter][network_ports][$portcounter][protocol]"} = $protocol;
									$data{"network_interfaces[$niccounter][ip_addresses][$ipcounter][network_ports][$portcounter][number]"} = $port;
									$data{"network_interfaces[$niccounter][ip_addresses][$ipcounter][network_ports][$portcounter][apps]"} = $app;
									$portcounter++;
								}
							}
						}
						else
						{
							$data{"network_interfaces[$niccounter][ip_addresses][$ipcounter][$ipfield]"} = $ipvalue;
						}
					}
					$ipcounter++;
				}
			}
			else
			{
				# The library gathers a few bits of data that the server
				# doesn't support.  Filter those out.
				next if ($field eq 'txerrs');
				next if ($field eq 'rxerrs');

				$data{"network_interfaces[$niccounter][$field]"} = $value;
			}
		}
		$niccounter++;
	}
	# Mark our NIC data as authoritative so that the server properly
	# updates its records (removing any NICs and IPs we don't specify)
	$data{"network_interfaces[authoritative]"} = 1;

	$data{name} = nVentory::OSInfo::getfqdn();
	$data{'name_aliases[name]'} = join(',', nVentory::OSInfo::getaliases());
	$data{'operating_system[variant]'} = nVentory::OSInfo::getos();
	$data{'operating_system[version_number]'} = nVentory::OSInfo::getosversion();
	$data{'operating_system[architecture]'} = nVentory::OSInfo::getosarch();
	$data{kernel_version} = nVentory::OSInfo::getkernelversion();
	$data{os_memory} = nVentory::OSInfo::getosmemory();
	$data{swap} = nVentory::OSInfo::getswapmemory();
	my %oscpus = nVentory::OSInfo::get_os_cpu_count();
	$data{os_processor_count} = $oscpus{physical} if $oscpus{physical};
	$data{os_virtual_processor_count} = $oscpus{virtual} if $oscpus{virtual};
	$data{timezone} = nVentory::OSInfo::get_timezone();
        my $temp_cpu_percent = nVentory::OSInfo::getcpupercent();
        if (($temp_cpu_percent =~ /\S/) && ($temp_cpu_percent ne 'false')) {
          $data{'utilization_metric[percent_cpu][value]'} = $temp_cpu_percent;
        }
        $data{'utilization_metric[login_count][value]'} = nVentory::OSInfo::getlogincount();
        my %disk_usage = nVentory::OSInfo::getdiskusage();
	$data{used_space} = $disk_usage{used_space};
	$data{avail_space} = $disk_usage{avail_space};
	my %volumes = nVentory::OSInfo::getvolumes();
	foreach my $key (keys(%volumes)) {
		$data{$key} = $volumes{$key};
	}

	#
	# Gather hardware-related information
	#

	$data{'hardware_profile[manufacturer]'} = nVentory::HardwareInfo::get_host_manufacturer() || 'Unknown';
	$data{'hardware_profile[model]'} = nVentory::HardwareInfo::get_host_model() || 'Unknown';
	$data{serial_number} = nVentory::HardwareInfo::get_host_serial();

	$data{processor_manufacturer} = nVentory::HardwareInfo::get_cpu_manufacturer();
	$data{processor_model} = nVentory::HardwareInfo::get_cpu_model();
	$data{processor_speed} = nVentory::HardwareInfo::get_cpu_speed();
	$data{processor_count} = nVentory::HardwareInfo::get_cpu_count();
	$data{processor_core_count} = nVentory::HardwareInfo::get_cpu_core_count();
	$data{processor_socket_count} = nVentory::HardwareInfo::get_cpu_socket_count();
	$data{power_supply_count} = nVentory::HardwareInfo::get_power_supply_count();

        my $physical_memory = nVentory::HardwareInfo::get_physical_memory();
        $data{physical_memory} = $physical_memory unless (!$physical_memory);
	# The library returns an array of the sizes of each of the DIMMs in the
	# system.  We want to condense that into an easier to read format for
	# storage in the database.  So "1024,1024,1024,1024" becomes "4@1024"
	# and "512,512,1024,1024" becomes "2@512,2@1024"
	my %physical_memory_sizes;
	foreach my $size (nVentory::HardwareInfo::get_physical_memory_sizes())
	{
		$physical_memory_sizes{$size}++;
	}
	my @physical_memory_sizes;
	sub numerically_if_possible
	{
		if ($a =~ /^\d+$/ && $b =~ /^\d+$/)
		{
			$a <=> $b;
		}
		else
		{
			$a cmp $b;
		}
	}
	foreach my $size (sort numerically_if_possible keys %physical_memory_sizes)
	{
		push @physical_memory_sizes, $physical_memory_sizes{$size} . 'x' . $size;
	}
        my $temp_physical_memory_sizes = join ',', @physical_memory_sizes;
        $data{physical_memory_sizes} = $temp_physical_memory_sizes unless (!$temp_physical_memory_sizes);
	# Switchport detection depends on if virtual or not

	## XEN HOST <=> GUEST REGISTRATION
	if ($data{kernel_version} =~ /xenU?$/)
	{
		$data{virtualarch} = 'xen';
        	my $xen_status = nVentory::OSInfo::getxenstatus();
		if ($xen_status =~ /xenu/)
		{
			print "XEN GUEST VM.\n";
			$data{virtualmode} = 'guest';
        		$data{'hardware_profile[manufacturer]'} = 'Xen' if ($data{'hardware_profile[manufacturer]'} eq 'Unknown');
	                $data{'hardware_profile[model]'} = 'VM' if ($data{'hardware_profile[model]'} eq 'Unknown');
		}
		elsif ($xen_status =~ /xen0/)
		{
			print "XEN MASTER HOST.  Listing all guest vm:\n";
			$data{virtualmode} = 'host';
			my %xenhostinfo = nVentory::OSInfo::getxenhostinfo;
			foreach my $xenguest (@{$xenhostinfo{'guests'}})
			{
				print "$xenguest\n";
				my $size;
				my $sparse_size;
				if (-e "$XEN_IMGDIR/$xenguest.img") 
				{
					## Actual file size of disk image ##
					$size = -s "$XEN_IMGDIR/$xenguest.img";
					$size = round($size / 1024);

					## True sparse file size (in use) ##
					my $st = stat("$XEN_IMGDIR/$xenguest.img");
					my $blocks = $st->blocks;
					$sparse_size = $blocks * 512;
					$sparse_size = round($sparse_size / 1024);
				}
				print "   IMG SIZE: $size KB\n" if $size ;
				print "   SPARSE SIZE: $sparse_size KB\n" if $sparse_size;
				$data{"vmguest[$xenguest][vmimg_size]"} = $size;
				$data{"vmguest[$xenguest][vmspace_used]"} = $sparse_size;
				## subroutine to round the integer when divided
				sub round {
				    my($number) = shift;
				    return int($number + .5);
				}
			}
		}
	}


	## VMWARE HOST <=> GUEST REGISTRATION
       	my $vmware_status = nVentory::OSInfo::getvmwarestatus();
	if ($vmware_status eq 'vmware_server')
	{
		$data{virtualarch} = 'vmware';
		print "VMWARE MASTER HOST.  Listing all guest vm data:\n";
		$data{virtualmode} = 'host';
		my %vmwarehostdata = nVentory::OSInfo::getvmwarehostinfo;
		unless (scalar(keys %vmwarehostdata) == 0)
		{
			foreach my $key (sort(keys %vmwarehostdata))
			{
				$data{$key} = $vmwarehostdata{$key};
				print "$key = $vmwarehostdata{$key}\n";
			}
		}
	}
	elsif ($vmware_status eq 'vmware')
	{
		$data{virtualarch} = 'vmware';
		print "VMWARE GUEST\n";
	}

	$params{virtualarch} = $data{virtualarch} if $data{virtualarch};
	$params{virtualmode} = $data{virtualmode} if $data{virtualmode};

        ## STORAGE - convert storage hash to RESTful format ##
        my %storage = nVentory::HardwareInfo::getstoragedata(\%params);
        my $strg_counter = 0;
	my $drivecounter = 0;
	my $volumecounter = 0;
	# note that controllers, drives and volumes each have different @exceptions (fields to ignore) from each other
        while (my ($ctrlrkey, $ctrlrref) = each %storage)
        {
		my %ctrlrhash = %{$ctrlrref};
                if ($ctrlrhash{'description'})
                {
                        $data{"storage_controllers[$strg_counter][name]"} = $ctrlrhash{'description'};
                }
                else
                {
                        $data{"storage_controllers[$strg_counter][name]"} = $ctrlrhash{'logicalname'};
                }
                ######################################################################
                ## if needs external modules due to custom raid controller commands ##
                ######################################################################
                if (($ctrlrhash{'product'}) && ($ctrlrhash{'product'} =~ /Smart Array/))
		{
			my %result = nVentory::CompaqSmartArray::parse_storage();
			foreach my $key (keys %result)
			{
				$data{"storage_controllers[$strg_counter]$key"} = $result{$key};
			}
		}
                #### END CUSTOM RAID ARRAY MODULE ####

		while (my ($ctrlrkey, $ctrlrvalue) = each %ctrlrhash) 
		{
			if (ref($ctrlrvalue) eq "HASH") 
			{
				my %drivehash = %{$ctrlrvalue};
				unless ($drivehash{'class'} eq 'disk') 
				{
					%drivehash = find_classhash(\%drivehash, 'disk');
				}
				next unless %drivehash;
				while (my ($drivefield, $drivevalue) = each %drivehash)
				{
					if (ref($drivevalue) eq "HASH")
					{
						my %volumehash = %{$drivevalue};
						unless ($volumehash{'class'} eq 'volume')
						{
							%volumehash = find_classhash(\%volumehash, 'volume');
						}
						next unless %volumehash;
						while (my ($volumefield, $volumevalue) = each %volumehash)
						{ 
							if ($volumefield eq 'id')
							{
								$data{"storage_controllers[$strg_counter][drives][$drivecounter][volumes][$volumecounter][name]"} = $volumevalue;
								next;
							}
							$data{"storage_controllers[$strg_counter][drives][$drivecounter][volumes][$volumecounter][$volumefield]"} = $volumevalue;
						} 
						$volumecounter++;
					} else {
						if ($drivefield eq 'id')
						{
							$data{"storage_controllers[$strg_counter][drives][$drivecounter][name]"} = $drivevalue;
							next;
						}
						$data{"storage_controllers[$strg_counter][drives][$drivecounter][$drivefield]"} = $drivevalue;
					} # if (ref($drivevalue) eq "HASH")
				} # while (my ($drivefield, $drivevalue) = each %drivehash)
				$drivecounter++;
			} else {
				$data{"storage_controllers[$strg_counter][$ctrlrkey]"} = $ctrlrvalue;
			} # if (ref($ctrlrvalue) eq "HASH")
		} # while (my ($ctrlrkey, $ctrlrvalue) = each %ctrlrhash)
		$strg_counter++;
	} # while (my ($ctrlrkey, $ctrlrref) = each %storage)
	$data{"storage_controllers[authoritative]"} = 1;

	$data{uniqueid} = nVentory::HardwareInfo::get_uniqueid();

        ## recursive subroutine used by above
	sub find_classhash {
	        my %tmphash = %{$_[0]};
	        my $class = $_[1];
	        my %results;
	        if (($tmphash{'class'}) && ($tmphash{'class'}  eq $class))
	        {
	                return %tmphash;
	        } else {
	                while (my ($k,$v) = each %tmphash)
	                {
	                        if (ref($v) eq 'HASH')
	                        {
	                                %results = find_classhash(\%{$v}, $class);
	                        }
	                }
	        }
	        return %results;
	}

	#
	# Report data to server
	#

	# Check to see if there's an existing entry for this host that matches
	# our unique id.  If so we want to update it, even if the hostname
	# doesn't match our current hostname (as it probably indicates this
	# host was renamed).
	my %results;
	if ($data{uniqueid})
	{
                my %getdata;
                $getdata{'objecttype'} = 'nodes';
                $getdata{'exactget'} = {'uniqueid' => [$data{uniqueid}]};
                $getdata{'login'} = 'autoreg';
                %results = get_objects(\%getdata);
	}

	# If we failed to find an existing entry based on the unique id
	# fall back to the hostname.  This may still fail to find an entry,
	# if this is a new host, but that's OK as it will leave %results
	# as undef, which triggers set_objects to create a new entry on the
	# server.
	if (!%results && $data{name})
	{
                my %getdata;
                $getdata{'objecttype'} = 'nodes';
                $getdata{'exactget'} = {'name' => [$data{name}]};
                $getdata{'login'} = 'autoreg';
                %results = get_objects(\%getdata);
	}

	set_objects('nodes', \%results, \%data, 'autoreg');
}

# The first argument is a reference to a hash returned by a 'nodes' call
# to get_objects
# The second argument is a reference to a hash returned by a 'node_groups'
# call to get_objects
# NOTE: For the node groups you must have requested that the server include 'nodes' in the result
sub add_nodes_to_nodegroups
{
	my ($nodesref, $nodegroupsref, $login, $password_callback) = @_;
	my %nodes = %$nodesref;
	my %nodegroups = %$nodegroupsref;

	# The server only supports setting a complete list of members of
	# a node group.  So we need to retreive the current list of members
	# for each group, merge in the additional nodes that the user wants
	# added, and pass that off to set_nodegroup_assignments to perform
	# the update.
	# FIXME: This should talk directly to the node_group_node_assignments
	# controller, so that we aren't exposed to the race conditions this
	# method currently suffers from.
	foreach my $nodegroup (keys %nodegroups)
	{
                my %real_nodes;
                foreach my $realnode (split(',', $nodegroups{$nodegroup}->{real_nodes_names}))
                {
                        $real_nodes{$realnode} = 1;
                }

		# Use a hash to merge the current and new members and
		# eliminate duplicates
		my %merged_nodes;

		%merged_nodes = %nodes;

		# now merge in the pre-existing nodes from that ng
		foreach my $node (@{$nodegroups{$nodegroup}->{nodes}})
		{
			my $name = $node->{name};
			# unless the node is a virtual
			$merged_nodes{$name} = $node if $real_nodes{$name};
		}

		set_nodegroup_node_assignments(\%merged_nodes, {$nodegroup => $nodegroups{$nodegroup}}, $login, $password_callback);
	}
}

sub add_comment_to_obj
{
	my ($objecttypes, $objref, $comment, $login, $password_callback) = @_;
	my %objects = %$objref;
	foreach my $key (keys %objects) {
		my @under = split(/_/,$objecttypes);
		my @upper = map(ucfirst, @under);
		my $camelized_objecttype = singularize(join('',@upper));
        	set_objects('comments', undef,
                                {  'comment' => $comment,
				   'commentable_id' => ${${objects}{$key}}{"id"},
				   'commentable_type' => $camelized_objecttype,
				}, 
                             $login, $password_callback);
	}
}
# The first argument is a reference to a hash returned by a 'nodes' call
# to get_objects
# The second argument is a reference to a hash returned by a 'node_groups'
# call to get_objects
# NOTE: For the node groups you must have requested that the server include 'nodes' in the result
sub remove_nodes_from_nodegroups
{
	my ($nodesref, $nodegroupsref, $login, $password_callback) = @_;
	my %nodes = %$nodesref;
	my %nodegroups = %$nodegroupsref;

	# The server only supports setting a complete list of members of
	# a node group.  So we need to retreive the current list of members
	# for each group, remove the nodes that the user wants
	# removed, and pass that off to set_nodegroup_assignments to perform
	# the update.
	# FIXME: This should talk directly to the node_group_node_assignments
	# controller, so that we aren't exposed to the race conditions this
	# method currently suffers from.
	foreach my $nodegroup (keys %nodegroups)
	{

		# build the list of ALL nodes minus the nodes to be deleted
		my %real_nodes;
		foreach my $realnode (split(',', $nodegroups{$nodegroup}->{real_nodes_names}))
		{
			$real_nodes{$realnode} = 1;
		}
		my %desired_nodes;

		foreach my $node (@{$nodegroups{$nodegroup}->{nodes}})
		{
			if (my $name = $node->{name}) {
				# don't process virtuals
				$desired_nodes{$name} = $node if ( (!$nodes{$name}) && ($real_nodes{$name}) )
			}
		}

		set_nodegroup_node_assignments(\%desired_nodes, {$nodegroup => $nodegroups{$nodegroup}}, $login, $password_callback);
	}
}
# The first argument is a reference to a hash returned by a 'nodes' call
# to get_objects
# The second argument is a reference to a hash returned by a 'node_groups'
# call to get_objects
sub set_nodegroup_node_assignments
{
        my ($nodesref, $nodegroupsref, $login, $password_callback) = @_;
        my %nodes = %$nodesref;
        my @node_ids;
        if ( (scalar %nodes) eq 0 )
        {
                push(@node_ids, 'nil');
        }
        else
        {
                foreach my $node (keys %nodes)
                {
                        my $id = $nodes{$node}->{id};

                        if ($id)
                        {
                                push(@node_ids, $id);
                        }
                        else
                        {
                                # Of course it may not have a name field either...  :)
                                warn "set_nodegroup_node_assignments passed a bogus nodes hash, ", $node->{name}, " has no id field\n";
                        }
                }
        }

        my %nodegroupdata;
        $nodegroupdata{'node_group_node_assignments[nodes][]'} = \@node_ids;

        set_objects('node_groups', $nodegroupsref, \%nodegroupdata, $login, $password_callback);
}

# Both arguments are references to a hash returned by a 'node_groups'
# call to get_objects
# NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
sub add_nodegroups_to_nodegroups
{
	my ($child_groupsref, $parent_groupsref, $login, $password_callback) = @_;
	my %child_groups = %$child_groupsref;
	my %parent_groups = %$parent_groupsref;

	# The server only supports setting a complete list of assignments for
	# a node group.  So we need to retreive the current list of assignments
	# for each group, merge in the additional node groups that the user wants
	# added, and pass that off to set_nodegroup_nodegroup_assignments to perform
	# the update.
	# FIXME: This should talk directly to the node_group_node_groups_assignments
	# controller, so that we aren't exposed to the race conditions this
	# method currently suffers from.
	foreach my $parent_group (keys %parent_groups)
	{
		# Use a hash to merge the current and new members and
		# eliminate duplicates
		my %merged_nodegroups;

		%merged_nodegroups = %child_groups;

		foreach my $current_child (@{$parent_groups{$parent_group}->{child_groups}})
		{
			my $name = $current_child->{name};
			$merged_nodegroups{$name} = $current_child;
		}

		set_nodegroup_nodegroup_assignments(\%merged_nodegroups, {$parent_group => $parent_groups{$parent_group}}, $login, $password_callback);
	}
}
# Both arguments are references to a hash returned by a 'node_groups'
# call to get_objects
# NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
sub remove_nodegroups_from_nodegroups
{
	my ($child_groupsref, $parent_groupsref, $login, $password_callback) = @_;
	my %child_groups = %$child_groupsref;
	my %parent_groups = %$parent_groupsref;

	# The server only supports setting a complete list of assignments for
	# a node group.  So we need to retrieve the current list of assignments
	# for each group, remove the node groups that the user wants
	# removed, and pass that off to set_nodegroup_nodegroup_assignments to perform
	# the update.
	# FIXME: This should talk directly to the node_group_node_groups_assignments
	# controller, so that we aren't exposed to the race conditions this
	# method currently suffers from.
	foreach my $parent_group (keys %parent_groups)
	{
		my %desired_child_groups;

		foreach my $current_child (@{$parent_groups{$parent_group}->{child_groups}})
		{
			my $name = $current_child->{name};
			if (!grep($_ eq $name, keys %child_groups))
			{
				$desired_child_groups{$name} = $current_child;
			}
		}

		set_nodegroup_nodegroup_assignments(\%desired_child_groups, {$parent_group => $parent_groups{$parent_group}}, $login, $password_callback);
	}
}
# Both arguments are references to a hash returned by a 'node_groups'
# call to get_objects
sub set_nodegroup_nodegroup_assignments
{
	my ($child_groupsref, $parent_groupsref, $login, $password_callback) = @_;
	my %child_groups = %$child_groupsref;

	my @child_ids;
	foreach my $child_group (keys %child_groups)
	{
		my $id = $child_groups{$child_group}->{id};

		if ($id)
		{
			push(@child_ids, $id);
		}
		else
		{
			# Of course it may not have a name field either...  :)
			warn "set_nodegroup_nodegroup_assignments passed a bogus child groups hash, ", $child_group->{name}, " has no id field\n";
		}
	}
        # if there are NO child_groups, HTTP::Common::Request will discard the empty hash instead of url encoding it.
        # Added code to server NodeGroupsController#update to watch for the 'nil' token and convert accordingly
        if (!@child_ids) { push(@child_ids, 'nil') }

	my %nodegroupdata;
	$nodegroupdata{'node_group_node_group_assignments[child_groups][]'} = \@child_ids;

	set_objects('node_groups', $parent_groupsref, \%nodegroupdata, $login, $password_callback);
}

sub setdebug
{
	my ($newdebug) = @_;
	$debug = $newdebug;
	nVentory::HardwareInfo::setdebug($newdebug);
	nVentory::OSInfo::setdebug($newdebug);
}

sub setdryrun
{
        ($dryrun) = @_;
	warn "Enabling dry-run mode\n";
}

1;
