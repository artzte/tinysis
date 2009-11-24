class CreateStatuses < ActiveRecord::Migration
  def self.up
    create_table :statuses do |t|
			t.column :month, :datetime, :null => false
			t.column :academic_status, :integer, :null => false, :default => Status::STATUS_ACCEPTABLE
			t.column :attendance_status, :integer, :null => false, :default => Status::STATUS_ACCEPTABLE
			t.column :fte, :float, :default => 1.0
			t.column :creator_id, :integer, :null => false
			t.column :created_on, :datetime, :null => false
			t.column :updated_on, :datetime, :null => false
			t.column :statusable_id, :integer
			t.column :statusable_type, :string
    end
  end

  def self.down
    drop_table :statuses
  end
end
