class AddCoordinatorFieldToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :coordinator_id, :integer
  end

  def self.down
    remove_column :users, :coordinator_id
  end
end
