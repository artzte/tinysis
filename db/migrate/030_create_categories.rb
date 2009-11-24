class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column :category_name, :string, :null => false
			t.column :sequence, :integer, :null => false
    end
  end

  def self.down
    drop_table :categories
  end
end
