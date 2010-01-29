##############################################################################
# Functions for gathering info about Compaq Smart Array storage
##############################################################################
#Smart Array 5i/532
#
# Valid storage_controllers attrs:
# ["name", "controller_type", "physical", "businfo", "slot", "firmware", "cache_size", "batteries", "node_id", "created_at", "updated_at", "logicalname", "product", "description", "physid", "vendor", "handle"]
# Valid volumes attrs:
# ["name", "volume_type", "configf", "volume_server_id", "description", "created_at", "updated_at", "capacity", "size", "vendor", "businfo", "serial", "physid", "dev", "logicalname"]
# Valid drives attrs:
# ["name", "storage_controller_id", "logicalname", "vendor", "physid", "businfo", "handle", "serial", "description", "product", "size", "dev", "created_at", "updated_at"]
#
# SAMPLE OUTPUT:
# Smart Array 5i in Slot 0      ()
# 
#    array A (Parallel SCSI, Unused Space: 0 MB)
# 
#       logicaldrive 1 (33.9 GB, RAID 1+0, OK)
# 
#       physicaldrive 2:0   (port 2:id 0 , Parallel SCSI, 36.4 GB, OK)
#       physicaldrive 2:1   (port 2:id 1 , Parallel SCSI, 36.4 GB, OK)
# 
#    array B (Parallel SCSI, Unused Space: 0 MB)
# 
#       logicaldrive 2 (273.5 GB, RAID 1+0, OK)
# 
#       physicaldrive 2:2   (port 2:id 2 , Parallel SCSI, 146.8 GB, OK)
#       physicaldrive 2:3   (port 2:id 3 , Parallel SCSI, 146.8 GB, OK)
#       physicaldrive 2:4   (port 2:id 4 , Parallel SCSI, 146.8 GB, OK)
#       physicaldrive 2:5   (port 2:id 5 , Parallel SCSI, 146.8 GB, OK)
#

package nVentory::CompaqSmartArray;

use strict;
use warnings;
use Data::Dumper;

my $debug;
my %data;

sub parse_storage {
  unless (-x "/usr/sbin/lshw") {
    print "/usr/sbin/lshw command not found!\nSkipping storage controller parsing\n" ;
    return;
  }
  open(LSHW, "-|", "hpacucli ctrl all show config");

  my @content = <LSHW>;
  my %vol;

  foreach my $line (@content) {
    # controller info
    if ($line =~ /(Smart Array.*) in Slot\s+(\d+)\s+/) { 
      $data{"[name]"} = $1;
      $data{"[slot]"} = $2; 
    }

    # volume info
    if ($line =~ /(logicaldrive\s\d+)\s\(([\d\.]+)\s\w+,\s(.*),/) {
      $vol{"name"} = $1;
      # size convert to byte
      $vol{"size"} =  sprintf("%.f", ($2 * 1024 * 1024 * 1024));
      $vol{"volume_type"} = $3;
      $vol{"drivecount"} = 0;
    } 

    # drive info
    if ($line =~ /physical(drive\s\S+)\s+\((.*?),\s(.*?),\s([\d\.]+)/) {
      $data{"[drives][$vol{'drivecount'}][name]"} = $1;
      $data{"[drives][$vol{'drivecount'}][physid]"} = $2;
      $data{"[drives][$vol{'drivecount'}][businfo]"} = $3;
      $data{"[drives][$vol{'drivecount'}][size]"} =  sprintf("%.f", ($4 * 1024 * 1024 * 1024));
      # assuming this controller allows only 1 volume per drive
      $data{"[drives][$vol{'drivecount'}][volumes][0][name]"} = $vol{'name'};
      $data{"[drives][$vol{'drivecount'}][volumes][0][size]"} = $vol{'size'};
      $data{"[drives][$vol{'drivecount'}][volumes][0][volume_type]"} = $vol{'volume_type'};
      $vol{"drivecount"}++;
    }
  } # foreach my $line (@content) 
  
  return %data;
}

1;
