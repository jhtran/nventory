class UtilizationMetricsGlobal < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  belongs_to :utilization_metric_name
  
  validates_presence_of :utilization_metric_name_id, :value
  
  def validate
    if self.utilization_metric_name.name =~ /^(percent_cpu|login_count)$/
      errors.add_to_base("Value must be integers only\n") if self.value =~ /\D/
    end
  end 
  
  def self.default_search_attribute
    'node_id'
  end
  
  def before_create 
    self.assigned_at ||= Time.now 
  end
 
end
