class CreateEnrollments < ActiveRecord::Migration

  def self.up
		create_table :enrollments do |t|
			t.column :contract_id, :integer, :null => false
			t.column :participant_id, :integer, :null => false
			t.column :credits, :text, :null => false
			t.column :role, :integer, :null => false, :default => Enrollment::ROLE_STUDENT
			t.column :enrollment_status, :integer, :null => false, :default => Enrollment::STATUS_PROPOSED
			t.column :completion_status, :integer, :null => false, :default => Enrollment::COMPLETION_UNKNOWN
			t.column :completion_date, :datetime, :default => nil
			t.column :creator_id, :integer, :default =>  nil
			t.column :created_on, :datetime, :null => false
			t.column :updator_id, :integer, :default =>  nil
			t.column :updated_on, :datetime, :null => false
		end
  end

  def self.down
		drop_table :enrollments
  end
end
