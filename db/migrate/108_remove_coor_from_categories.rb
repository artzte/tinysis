class RemoveCoorFromCategories < ActiveRecord::Migration
  def self.up
		remove_column :categories, :coor
  end

  def self.down
    add_column :categories, :coor, :boolean, :default => false
  end
end
