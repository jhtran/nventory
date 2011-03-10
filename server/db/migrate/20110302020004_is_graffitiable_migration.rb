class IsGraffitiableMigration < ActiveRecord::Migration
  def self.up
    create_table :graffitis do |t|
      t.string :name, :default => ''
      t.string :value, :default => ''
      t.string  :graffitiable_type, :default => ''
      t.integer :graffitiable_id
      t.timestamps
    end
    
#    add_index :graffitis,     [:name, :graffitiable_id, :graffitiable_type]
  end
  
  def self.down
    drop_table :graffitis
  end
end
