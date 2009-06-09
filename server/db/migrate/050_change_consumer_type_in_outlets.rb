class ChangeConsumerTypeInOutlets < ActiveRecord::Migration
  def self.up
    change_column "outlets", "consumer_type", :string, :default => 'Node'
  end

  def self.down
    change_column "outlets", "consumer_type", :string
  end
end
