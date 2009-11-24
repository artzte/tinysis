class ConvertAbsences < ActiveRecord::Migration
  def self.up
    
    change_column :meetings, :meeting_date, :date
    remove_column :meetings, :agenda
    remove_column :meetings, :required
    remove_column :meeting_participants, :reason
    
    Meeting.delete_all
    MeetingParticipant.delete_all
    
    absences = Absence.find(:all, :include =>[:enrollment => :contract])
    absences_by_contract = absences.group_by{|a| a.enrollment.contract}
    
    absences_by_contract.each do |contract,contract_absences|
      contract_absences_by_date = contract_absences.group_by{|a| a.absence_date}
      contract_absences_by_date.each do |date, absences|
        meeting = Meeting.create(:contract_id => contract.id, :meeting_date => date)
        absences.each do |absence|
          MeetingParticipant.create(:meeting_id => meeting.id, :enrollment_id => absence.enrollment_id, :participation => MeetingParticipant::ABSENT)
        end
      end
    end

  end

  def self.down
    change_column :meetings, :meeting_date, :datetime
    add_column :meetings, :agenda, :text
    add_column :meetings, :required, :boolean
    add_column :meeting_participants, :reason, :integer
  end
end
