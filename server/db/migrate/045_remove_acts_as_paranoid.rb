class RemoveActsAsParanoid < ActiveRecord::Migration
  require 'rexml/document'
  require 'ftools'
  @models = [ DatabaseInstance, DatabaseInstanceRelationship, Datacenter, HardwareProfile, IpAddress, NetworkInterface, NodeGroup, Node, OperatingSystem, Outlet, Status, Subnet, Vip, DatacenterRackAssignment, DatacenterVipAssignment, ServiceServiceAssignment, VirtualAssignment, NodeGroupNodeAssignment, NodeGroupNodeGroupAssignment, NodeDatabaseInstanceAssignment, RackNodeAssignment ]

  def self.up
    @models.each do |model|
#       ## Export the rows that are going to be deleted
#       say "Backing up delete rows to /tmp/#{model.to_s.tableize}_backup.xml"
#       bfile = File.open("/tmp/#{model.to_s.tableize}_backup.xml",'w')
#         bfile.write model.find(:all,:conditions => "deleted_at is not null").to_xml
#       bfile.close
#       ## Make a backup copy of the export
#       File.copy("/tmp/#{model.to_s.tableize}_backup.xml","/tmp/#{model.to_s.tableize}_backup.#{Time.now.to_i}.xml")
#       ## Delete all of the paranoid deleted data (anything that has a 'deleted_at' field value)
#       say "Deleting rows from #{model.to_s.tableize}..."
#       model.find(:all).each do |obj| 
#         model.delete(obj.id) unless obj.deleted_at.nil? 
#       end
#       say "Deleting the 'deleted_at' column from #{model.to_s.tableize}"
#       ## Delete the 'deleted_at' column
       remove_column(model,:deleted_at)
    end
#    say "Purging :deleted_at nested changes from 'change' column of Audit table"
#    auditfile = File.open("/tmp/audit_change_column_backup.xml",'w')
#    audits = Audit.find(:all,:conditions => ["changes like ?", "%deleted_at%"])
#    auditfile.write audits.to_xml
#    File.copy("/tmp/audit_change_column_backup.xml","/tmp/audit_change_column_backup.#{Time.now.to_i}.xml")
#    audits.each do |audit|
#      unless (audit.changes.nil? || audit.changes.empty? || !audit.changes.kind_of?(Hash))
#        if audit.changes.key?("deleted_at")
#          audit.changes.delete("deleted_at")
#          audit.save
#        end
#      end
#    end
#    auditfile.close
#    say "Note:  Audit :change field entries of 'deleted_at' values cannot be restored by migration rollback."
  end

  def self.down
#    logf = File.open('/tmp/migration.log','w')
#    @models.each do |model|
#      ## Too many NGNA to restore , and some of these deleted were bad records causing loops from prior to validation in model
#      next if model == NodeGroupNodeAssignment
#      ### Re-add the 'deleted_at' column
#      say "Re-adding 'deleted_at' column to #{model.to_s.tableize} table"
#      add_column(model,:deleted_at,:datetime)
#      model.reset_column_information
#      ### Re-import the data from xml backup
#      file = File.new("/tmp/#{model.to_s.tableize}_backup.xml",'r')
#      xmldata = Hash.from_xml(file)
#      say "Re-importing data from xml file /tmp/#{model.to_s.tableize}_backup.xml"
#      model.reset_column_information
#      unless xmldata[model.to_s.tableize].nil?
#        xmldata[model.to_s.tableize].each do |xmlobj|
#          obj = model.new(xmlobj.except("id"))
#          obj.id = xmlobj["id"]
#          begin
#            obj.save
#          rescue Exception => exc
#            say "Exception trying to save #{model.to_s}, ID: #{xmlobj["id"]}\n#{exc.message}"
#            logf.write "Exception trying to save #{model.to_s}, ID: #{xmlobj["id"]}\n#{exc.message}"
#          end
#        end
#      end
#    end
#    logf.close
  end
end
