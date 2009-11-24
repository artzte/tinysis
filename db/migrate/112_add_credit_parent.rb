class AddCreditParent < ActiveRecord::Migration
  def self.up
    add_column :credits, :parent_credit_id, :integer
  end
  
  def self.down
    remove_column :credits, :parent_credit_id
  end
end
