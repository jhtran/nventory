class CreateServiceProfiles < ActiveRecord::Migration
  def self.up
    create_table :service_profiles do |t|
      t.column :service_id,  :integer
      t.column :dev_url,  :string
      t.column :qa_url,  :string
      t.column :stg_url,  :string
      t.column :prod_url,  :string
      t.column :repo_url, :string
      t.column :contact, :string
      t.column :codelang, :string
      t.column :external, :boolean
      t.column :pciscope, :boolean
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :service_profiles
  end
end
