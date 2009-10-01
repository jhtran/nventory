class MigrateExistingServices < ActiveRecord::Migration
  def self.up
    results = ServiceServiceAssignment.find(:all, :select => "child_id, parent_id")
    svcs = {}
    results.each do |obj|
      svcs[obj.child_id] = nil unless svcs[obj.child_id]
      svcs[obj.parent_id] = nil unless svcs[obj.parent_id]
    end

    svcs.keys.each do |svc_id|
      svc = Service.find(svc_id)
      if svc.service_profile.nil?
        puts "creating service_profile for #{svc.name}"
        svc.service_profile_attributes = {}
        svc.save
      end
    end
  end
  
  def self.down
  end
end
