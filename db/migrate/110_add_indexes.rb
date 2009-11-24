class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :statuses, :statusable_type
    add_index :notes, :notable_type
  end
  
  def self.down
    remove_index :statuses, :statusable_type
    remove_index :notes, :notable_type
  end
end
