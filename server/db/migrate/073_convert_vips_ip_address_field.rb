class ConvertVipsIpAddressField < ActiveRecord::Migration
  def self.up
    vipmap = {}
    Vip.all.each do |vip| 
    #  vipmap[vip.id] = vip.ip_address
    end
    #remove_column :vips, :ip_address
    add_column :vips, :ip_address_id, :integer
  end
  def self.down
  end
end
