class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.column :contract_id, :integer
      t.column :meeting_date, :datetime
      t.column :agenda, :text
      t.column :required, :boolean, :default => true
    end
    
    create_table :meeting_participants do |t|
      t.column :meeting_id, :integer
      t.column :enrollment_id, :integer
      t.column :participation, :integer
      t.column :reason, :integer
    end
  end

  def self.down
    drop_table :meetings
    drop_table :meeting_participants
  end
end
