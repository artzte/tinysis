class MeetingParticipant < ActiveRecord::Base

  OPTIONAL = 0
  PRESENT = 1
  ABSENT = 2
  TARDY = 3

  PARTICIPATION_STATUSES = [
  # deprecated
  #  {:name => "Optional", :value => OPTIONAL},
    {:name => "Present", :value => PRESENT},
    {:name => "Tardy", :value => TARDY},
    {:name => "Absent", :value => ABSENT},
  ]

  PARTICIPATION_STRINGS = {
    OPTIONAL => 'O',
    PRESENT => 'P',
    ABSENT => 'A',
    TARDY => 'T'
  }

  PARTICIPATION_NAMES = {
    OPTIONAL => 'Optional',
    PRESENT => 'Present',
    ABSENT => 'Absent',
    TARDY => 'Tardy'
  }

  CONTACT_TYPES = %w{Class COOR Other}

  belongs_to :enrollment
  belongs_to :meeting

  has_many :notes, :as => :notable, :dependent => :destroy

  def privileges(user)
    return meeting.privileges(user)
  end

end
