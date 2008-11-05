class AddVirtualFlagToNodeGroupNodeAssignments < ActiveRecord::Migration
  def self.up
    add_column :node_group_node_assignments, :virtual_assignment, :boolean
    
    NodeGroupNodeAssignment.all.each do |ngna|
      ngna.add_virtual_assignments_to_parents
    end
  end

  def self.down
    remove_column :node_group_node_assignments, :virtual_assignment
  end
end
