class ContractCategoryUpdates < ActiveRecord::Migration
  def self.up
    drop_table :contract_types
    
    add_column :categories, :public, :boolean, :default => false
    add_column :categories, :coor, :boolean, :default => false
    add_column :categories, :publicly_enrollable, :boolean
    add_column :categories, :statusable, :integer, :default => 0
  end

  def self.down
    create_table :contract_types do |t|
      t.column :name, :string, :null => false
    end
		
		remove_column :categories, :public
		remove_column :categories, :coor
		remove_column :categories, :publicly_enrollable
		remove_column :categories, :statusable
		
  end
end
