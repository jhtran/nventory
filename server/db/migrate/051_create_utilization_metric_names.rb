class CreateUtilizationMetricNames < ActiveRecord::Migration
  def self.up
    create_table :utilization_metric_names do |t|
      t.column :name,	:string
      t.column :description,	:text
      t.column :created_at,	:datetime
      t.column :updated_at,	:datetime
    end
    add_index :utilization_metric_names, :id
    UtilizationMetricName.reset_column_information
    UtilizationMetricName.create :name => 'percent_cpu'
  end

  def self.down
    drop_table :utilization_metric_names
  end
end
