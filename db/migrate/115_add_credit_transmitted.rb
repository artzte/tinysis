class AddCreditTransmitted < ActiveRecord::Migration
  def self.up
    
    add_column :credit_assignments, :credit_transmittal_batch_id, :integer
    remove_column :credit_assignments, :district_finalized
    remove_column :credit_assignments, :district_finalized_on
    remove_column :credit_assignments, :district_finalized_by
    
    create_table :credit_transmittal_batches do |t|
			t.column :finalized_on, :datetime, :null => false
			t.column :finalized_by, :string, :null => false
			t.column :transmitted, :boolean, :null => false, :default => false
			t.column :transmitted_on, :datetime
			t.column :transmitted_by, :string
			t.column :transmitted_signature, :string
		end
  end
  
  def self.down
		add_column :credit_assignments, :district_finalized, :boolean
		add_column :credit_assignments, :district_finalized_on, :datetime
		add_column :credit_assignments, :district_finalized_by, :string
		remove_column :credit_assignments, :credit_transmittal_batch_id
		drop_table :credit_transmittal_batches
  end
end
