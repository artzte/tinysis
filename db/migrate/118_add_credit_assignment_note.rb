class AddCreditAssignmentNote < ActiveRecord::Migration
  def self.up
  	add_column :credit_assignments, :note, :string
  end

  def self.down
  	remove_column :credit_assignments, :note
  end
end
