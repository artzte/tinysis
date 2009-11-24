class ContractFieldsMovedToCategory < ActiveRecord::Migration
  def self.up
    remove_column :contracts, :enrolling
    remove_column :contracts, :public
  end

  def self.down
		add_column :contracts, :enrolling, :boolean, :default => false, :null => false
    add_column :contracts, :public, :boolean, :default => false, :null => false
  end
end
