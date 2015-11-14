module ContractHelper

	def meeting_string(contract)
	  meetings = ""
	  contract.timeslots.each do |t|
	    next if t.empty?

	    slot = ClassPeriod.from_timeslot_hash(t)
	    meetings << slot.timeslot_string << "; "
	  end
	  meetings.chomp("; ")
	end

	# Tab filter helpers
	def hide_ealrs?
	  !@privs[:edit] && @contract.ealrs.empty?
	end

	def print_ealrs_class
	  return 'dontprint' if @contract.ealrs.empty?
	end

	def hide_details?
	  !@privs[:edit] && details_blank?
	end

	def print_details_class
	  return 'dontprint' if details_blank?
	end

	def details_blank?
	   @contract.learning_objectives.blank? && @contract.competencies.blank? && @contract.evaluation_methods.blank? && @contract.instructional_materials.blank?
	end

end
