class CreateUtilizationMetrics < ActiveRecord::Migration
  def self.up
    create_table :utilization_metrics do |t|
      t.column :utilization_metric_name_id,	:integer
      t.column :node_id,		:integer
      t.column :value,	:string
      t.column :assigned_at,    :datetime
      t.column :created_at,	:datetime
      t.column :updated_at,	:datetime
    end
    add_index :utilization_metrics, :id
  end

  def self.down
    drop_table :utilization_metrics
  end
end
