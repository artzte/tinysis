class Meeting < ActiveRecord::Base
  
  has_many :meeting_participants, :dependent => :destroy
  belongs_to :contract
	has_many :notes, :as => :notable, :dependent => :destroy
 
  named_scope :reverse_chrono, :order => 'meeting_date DESC' 

  # Return a hash describing privileges of the specified user
	# on this meeting

	def privileges(user)
	
		return TinyPrivileges.contract_child_object_privileges(user, contract)

	end
	
	def update_participant(enrollment_id, status)
	  
	  participant = meeting_participants.find(:first, :conditions => ["enrollment_id = ?", enrollment_id])
    if participant 
      participant.update_attribute(:status => status)
    else
      meeting_participants << MeetingParticipant.new(:status => status)
    end

	end	
	
	def create_participants
	  q = []
    q << "select enrollments.id from enrollments"
    q << "left join meeting_participants on meeting_participants.enrollment_id = enrollments.id and meeting_participants.meeting_id = #{self.id}"
    q << "where meeting_participants.id is null and enrollments.contract_id = #{self.contract_id} and enrollments.completion_status != #{Enrollment::COMPLETION_CANCELED}"
    
    missing = Enrollment.find_by_sql(q.join(' '))
    missing.each do |m|
      MeetingParticipant.create(:meeting_id => self.id, :enrollment_id => m.id, :participation=>0)
    end
    missing
	end
	
  def roll
    
    MeetingParticipant.find_by_sql("
      SELECT meeting_participants.*, CONCAT(users.last_name, ', ', users.first_name) AS participant_name FROM meeting_participants
      INNER JOIN enrollments ON meeting_participants.enrollment_id = enrollments.id AND enrollments.completion_status != #{Enrollment::COMPLETION_CANCELED}
      INNER JOIN users ON enrollments.participant_id = users.id
      WHERE meeting_participants.meeting_id = #{self.id}
      ORDER BY participant_name") 
    
  end

  def display_title
    if title.blank?
      %{Attendance for #{meeting_date.strftime('%A')}, #{meeting_date.strftime('%d %B %Y')}}
    else
      title
    end
 end
  
end
