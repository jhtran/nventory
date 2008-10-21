package nVentory::Client;

use strict;
use warnings;
use nVentory::HardwareInfo;
use nVentory::OSInfo;
use LWP::UserAgent;
use URI;
use HTTP::Cookies;
use HTTP::Request::Common; # GET, PUT, POST
use HTTP::Status;          # RC_* constants
use File::stat;            # Improved stat
use XML::LibXML;

my $debug;

my $SERVER = 'http://nventory';
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
				warn "Using server $SERVER from $configfile\n";
			}
			elsif ($key eq 'ca_file' && -f $value)
			{
				# This currently executes before anyone could call setdebug,
				# so the debug message is never printed.
				warn "Using CA file $value from $configfile\n" if ($debug);
				$ENV{HTTPS_CA_FILE} = $value;
			}
			elsif ($key eq 'ca_path' && -d $value)
			{
				# This currently executes before anyone could call setdebug,
				# so the debug message is never printed.
				warn "Using CA directory $value from $configfile\n" if ($debug);
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
		$password = 'autoreg';
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
		my $response = $ua->request(POST "$SERVER/accounts.xml", { 'foo' => 'bar' });
		if ($response->code == RC_FOUND)
		{
			warn "POST to $SERVER/accounts.xml was redirected, authenticating\n" if ($debug);
			# Logins need to go to HTTPS
			my $url = URI->new("$SERVER/login/login");
			$url->scheme('https');
			$password = &$password_callback() if (!$password);
			$response = $ua->request(POST $url, {'login' => $login, 'password' => $password});

			# The server always sends back a 302 redirect in response
			# to a login attempt.  You get redirected back to the login
			# page if your login failed, or redirected to your original
			# page or the main page if the login succeeded.
			my $locurl = URI->new($response->header('Location'));
			if ($response->code != RC_FOUND || $locurl->path eq '/login/login')
			{
				die "Authentication failed:\n", $response->content, "\n";
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
	my ($objecttype, $getref, $exactgetref, $includesref, $login) = @_;
	my %get = %$getref;
	my %exactget = %$exactgetref;
	
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
	if ($includesref)
	{
		$metaget{'include[]'} = $includesref;
	}

	#
	# Send the query to the server
	#

	my $url = URI->new("$SERVER/$objecttype.xml");
	$url->query_form(%metaget);
	my $ua = _get_ua($login);
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

	my %results = get_objects('node_groups', {}, {'name' => [$nodegroup]}, ['nodes', 'child_groups']);
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

	if (%results)
	{
		my $response;

		foreach my $result (keys %results)
		{
			my $id = $results{$result}->{id};

			# PUT to update an existing object
			if ($id)
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
				exit 1;
			}
		}
	}
	else
	{
		my $response;

		# POST to create a new node
		my $ua = _get_ua($login, $password_callback);
		warn "POST to URL: $SERVER/$objecttypes.xml\n" if ($debug);
		$response = $ua->request(POST "$SERVER/$objecttypes.xml", \%cleandata);

		if ($response->code != RC_CREATED)
		{
			warn "Response: ", $response->status_line, "\n";
			warn "Response content:\n", $response->content, "\n";
			exit 1;
		}
	}
}

sub register
{
	my ($dryrun) = @_;

	my %data;

	#
	# Gather software-related information
	#

	$data{name} = nVentory::OSInfo::gethostname();
	$data{'operating_system[variant]'} = nVentory::OSInfo::getos();
	$data{'operating_system[version_number]'} = nVentory::OSInfo::getosversion();
	$data{'operating_system[architecture]'} = nVentory::OSInfo::getosarch();
	$data{kernel_version} = nVentory::OSInfo::getkernelversion();
	$data{os_memory} = nVentory::OSInfo::getosmemory();
	$data{swap} = nVentory::OSInfo::getswapmemory();
	$data{os_processor_count} = nVentory::OSInfo::get_os_cpu_count();
	$data{timezone} = nVentory::OSInfo::get_timezone();
	$data{virtual_client_ids} = nVentory::OSInfo::get_virtual_client_ids();

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

	$data{physical_memory} = nVentory::HardwareInfo::get_physical_memory();
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
	$data{physical_memory_sizes} = join ',', @physical_memory_sizes;

	my %nicdata = nVentory::HardwareInfo::getnicdata();
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
						$data{"network_interfaces[$niccounter][ip_addresses][$ipcounter][$ipfield]"} = $ipvalue;
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

	$data{uniqueid} = nVentory::HardwareInfo::get_uniqueid();

	if ($data{'hardware_profile[model]'} eq 'VMware Virtual Platform')
	{
		my %results = get_objects('nodes', {'virtual_client_ids' => [$data{uniqueid}]}, {}, [], 'autoreg');
		if (scalar keys %results == 1)
		{
			$data{virtual_parent_node_id} = $results{(keys(%results))[0]}->{id};
		}
		elsif (scalar keys %results > 1)
		{
			warn "Multiple hosts claim this virtual client: ", join(',', sort keys %results), "\n";
		}
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
		%results = get_objects('nodes', {}, {'uniqueid' => [$data{uniqueid}]}, [], 'autoreg');
	}

	# If we failed to find an existing entry based on the unique id
	# fall back to the hostname.  This may still fail to find an entry,
	# if this is a new host, but that's OK as it will leave %results
	# as undef, which triggers set_objects to create a new entry on the
	# server.
	if (!%results && $data{name})
	{
		%results = get_objects('nodes', {}, {'name' => [$data{name}]}, [], 'autoreg');
	}

	if (!$dryrun)
	{
		set_objects('nodes', \%results, \%data, 'autoreg');
	}
	else
	{
		use Data::Dumper;
		print "Registration data:";
		print Dumper(\%data);
	}
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
		# Use a hash to merge the current and new members and
		# eliminate duplicates
		my %merged_nodes;

		%merged_nodes = %nodes;

		foreach my $node (@{$nodegroups{$nodegroup}->{nodes}})
		{
			my $name = $node->{name};
			$merged_nodes{$name} = $node;
		}

		set_nodegroup_node_assignments(\%merged_nodes, {$nodegroup => $nodegroups{$nodegroup}}, $login, $password_callback);
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
		my %desired_nodes;

		foreach my $node (@{$nodegroups{$nodegroup}->{nodes}})
		{
			my $name = $node->{name};
			if (!grep($_ eq $name, keys %nodes))
			{
				$desired_nodes{$name} = $node;
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

1;
