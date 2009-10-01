class AddUtilizationIndexes < ActiveRecord::Migration
  def self.up
    add_index("utilization_metric_names", "updated_at")
    add_index("utilization_metric_names", "created_at")
    add_index("utilization_metric_names", "name")

    add_index("utilization_metrics", "utilization_metric_name_id")
    add_index("utilization_metrics", "node_id")
    add_index("utilization_metrics", "value")
    add_index("utilization_metrics", "assigned_at")
    add_index("utilization_metrics", "created_at")
    add_index("utilization_metrics", "updated_at")

    add_index("utilization_metrics_by_node_groups", "utilization_metric_name_id", :name => "index_utilization_metrics_by_node_groups_on_utilz_metric_name_id")
    add_index("utilization_metrics_by_node_groups", "node_group_id")
    add_index("utilization_metrics_by_node_groups", "value")
    add_index("utilization_metrics_by_node_groups", "assigned_at")
    add_index("utilization_metrics_by_node_groups", "created_at")
    add_index("utilization_metrics_by_node_groups", "updated_at")

    add_index("utilization_metrics_globals", "utilization_metric_name_id")
    add_index("utilization_metrics_globals", "value")
    add_index("utilization_metrics_globals", "assigned_at")
    add_index("utilization_metrics_globals", "created_at")
    add_index("utilization_metrics_globals", "updated_at")

  end

  def self.down
    remove_index("utilization_metric_names", "updated_at")
    remove_index("utilization_metric_names", "created_at")
    remove_index("utilization_metric_names", "name")

    remove_index("utilization_metrics", "utilization_metric_name_id")
    remove_index("utilization_metrics", "node_id")
    remove_index("utilization_metrics", "value")
    remove_index("utilization_metrics", "assigned_at")
    remove_index("utilization_metrics", "created_at")
    remove_index("utilization_metrics", "updated_at")

    remove_index("utilization_metrics_by_node_groups", "utilz_metric_name_id")
    remove_index("utilization_metrics_by_node_groups", "node_group_id")
    remove_index("utilization_metrics_by_node_groups", "value")
    remove_index("utilization_metrics_by_node_groups", "assigned_at")
    remove_index("utilization_metrics_by_node_groups", "created_at")
    remove_index("utilization_metrics_by_node_groups", "updated_at")

    remove_index("utilization_metrics_globals", "utilization_metric_name_id")
    remove_index("utilization_metrics_globals", "value")
    remove_index("utilization_metrics_globals", "assigned_at")
    remove_index("utilization_metrics_globals", "created_at")
    remove_index("utilization_metrics_globals", "updated_at")
  end
end
