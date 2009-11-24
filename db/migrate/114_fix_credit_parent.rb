class FixCreditParent < ActiveRecord::Migration
  def self.up
    remove_column :credits, :parent_credit_id
    add_column :credit_assignments, :parent_credit_assignment_id, :integer
  end
  
  def self.down
    add_column :credits, :parent_credit_id, :integer
    remove_column :credit_assignment, :parent_credit_assignment_id
  end
end
