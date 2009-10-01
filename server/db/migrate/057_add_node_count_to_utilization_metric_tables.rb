class AddNodeCountToUtilizationMetricTables < ActiveRecord::Migration
  def self.up
    # add a column to node so it can have a hardware profile
    add_column "utilization_metrics_by_node_groups", "node_count", :integer
    add_column "utilization_metrics_globals", "node_count", :integer
  end

  def self.down
    remove_column "utilization_metrics_by_node_groups", "node_count"
    remove_column "utilization_metrics_globals", "node_count"
  end
end
