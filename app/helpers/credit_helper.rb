module CreditHelper

  include NoteHelper

  def credit_container_id(parent)
    if parent.is_a? CreditAssignment
      "ca_user_#{parent.id}"
    else
      "ca_#{parent.class.to_s.downcase}_#{parent.id}"
    end
  end

	def credits_formatted(object)

	  credits = object.credit_assignments.collect{|c| c.credit_string }
	  if credits.blank?
	    "No credits assigned."
	  else
	    credits.join('; ')
	  end

	end

end
