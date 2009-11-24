class CreateAbsences < ActiveRecord::Migration

  def self.up
    create_table :absences do |t|
			t.column :enrollment_id, :integer, :null => false
			t.column :absence_date, :datetime, :null => false
			t.column :reason, :integer, :null => false, :default => Absence::REASON_UNKNOWN
    end
  end

  def self.down
    drop_table :absences
  end
end
