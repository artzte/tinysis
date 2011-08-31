class AddHomeroomFlagToCategories < ActiveRecord::Migration
  def self.up
  
    add_column :categories, :homeroom, :tinyint, :default => 0
    Category.update_all("homeroom=1", "name = 'COOR'")
  end

  def self.down
    remove_column :categories, :homeroom
  end
end
