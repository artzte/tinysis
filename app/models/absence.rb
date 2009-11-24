class Absence < ActiveRecord::Base
	belongs_to :enrollment
	has_many :notes, :as => :notable, :dependent => :destroy
	REASON_UNKNOWN = 0
	REASON_EXCUSED = 1
	REASON_NAMES = {
		REASON_UNKNOWN => "Unknown",
		REASON_EXCUSED => "Excused" }
	attr_accessor :absent, :note

	# Return a hash describing privileges of the specified user
	# on this absence

	def privileges(user)
		return enrollment.privileges(user)
	end
end
