class CreateAssignments < ActiveRecord::Migration

  def self.up
		create_table :assignments do |table|
			table.column :contract_id, :integer
			table.column :name, :string, :limit => 100, :null => false
			table.column :description, :text, :limit => 2.kilobytes
			table.column :due_date, :datetime, :null => false
			table.column :importance, :integer, :default => 0, :null => false
			table.column :active, :boolean, :default => true, :null => false
			table.column :created_on, :datetime
			table.column :updated_on, :datetime
			table.column :creator_id, :integer
			table.column :updator_id, :integer
		end
  end

  def self.down
		drop_table :assignments
  end
end
