class AddNmapLastScannedAtToIpAddress< ActiveRecord::Migration
  def self.up
    add_column 'ip_addresses', :nmap_last_scanned_at, :datetime
  end

  def self.down
    remove_column 'ip_addresses', :nmap_last_scanned_at
  end
end
