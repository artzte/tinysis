class Notable < ActiveRecord::Migration
  def add_reference ref
    add_column :notes, ref, :integer
    add_index :notes, ref, :name => "ix_notes_#{ref}"
  end

  def up
    self.add_reference :absence_id
    self.add_reference :assignment_id
    self.add_reference :credit_assignment_id
    self.add_reference :enrollment_id
    self.add_reference :learningplan_id
    self.add_reference :meeting_participant_id
    self.add_reference :status_id
    self.add_reference :turnin_id

    Note.all.each do |note|
      note.update_attribute "#{note.notable_type.underscore}_id", note.notable_id
    end
  end
end
