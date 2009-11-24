class CreateTerms < ActiveRecord::Migration

  def self.up
    create_table :terms do |table|
      table.column :name, :string, :null => false
			table.column :schoolyear, :integer, :null => false, :default => 0
			table.column :active, :boolean, :default => true, :null => false
			table.column :term, :integer, :default => 0, :null => false
    end
  end

  def self.down
    drop_table :terms
  end
end
