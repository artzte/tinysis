class Creditables < ActiveRecord::Migration
  def self.up
    
		create_table :credit_assignments do |t|
			t.column :creditable_id, :integer, :null => false
			t.column :creditable_type, :string, :null => false
			t.column :credit_id, :integer, :null => false
			t.column :credit_hours, :float, :null => false, :default => 0.5
			
			t.column :enrollment_finalized_on, :datetime
			
			t.column :enrollment_id, :integer
			
			t.column :contract_name, :string
			t.column :contract_facilitator, :string
			t.column :contract_year, :integer
			t.column :contract_term, :string
			
			t.column :district_finalize_approved, :boolean
			t.column :district_finalize_approved_by, :string
			t.column :district_finalize_approved_on, :datetime
			
			t.column :district_finalized, :boolean
			t.column :district_finalized_on, :datetime
			t.column :district_finalized_by, :string
		end
		
  end

  def self.down
    
		drop_table :credit_assignments
		
  end
  
end
