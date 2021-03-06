class AddContactTypeToMeetingParticipants < ActiveRecord::Migration

  def self.up
    add_column :meeting_participants, :contact_type, :string, :nil => false, :default => "class", :limit => 8
  end

  def self.down
    remove_column :meeting_participants, :contact_type
  end

end
