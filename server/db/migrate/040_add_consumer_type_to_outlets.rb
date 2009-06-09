class AddConsumerTypeToOutlets < ActiveRecord::Migration
  def self.up
    add_column "outlets", "consumer_type", :string
    add_index :outlets, :consumer_type
  end

  def self.down
    remove_column "outlets", "consumer_type"
  end
end
