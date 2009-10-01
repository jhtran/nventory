class TestDataController < ApplicationController
  def populate_fake_node_metrics
    logf = File.open('/tmp/test','w')
    (1..10).each do |num_days_ago| 
      Node.all.each do |node|
puts "processing #{node.name}"
        a = UtilizationMetric.new
        a.utilization_metric_name = UtilizationMetricName.find(1)
        a.node = node
        a.value = rand(100)
        a.assigned_at = num_days_ago.days.ago
        a.save
        node.utilization_metrics << a
      end
    end
    logf.close
  end
end
