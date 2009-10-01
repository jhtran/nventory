class CreateUtilizationMetricsNameLoginCount < ActiveRecord::Migration
  def self.up
    UtilizationMetricName.create :name => 'login_count'
  end

  def self.down
    object = UtilizationMetricName.find_by_name('login_count')
    object.destroy
  end
end
