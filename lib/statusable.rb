module Statusable
	
	# gets the specified month's status record for this object, and creates
	# it if it's not already made
	def get_status(month, user)

		# find or create this month's status record
		status = statuses.collect.find{|s| s.month == month}
		if status.nil?
			status = Status.create(:month => month, :author => user)
			statuses << status
		end
		
		status

	end

end