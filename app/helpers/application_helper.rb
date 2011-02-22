# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  include TinyForms
  include TinyTabs
  
	# Convert a hash to a string that can be round-tripped back
	# to a hash. Works with hashes in which the value is a string
	# or a simple type such as an integer or float

	def hash_to_string(theHash)
		ret = ""
		theHash.each do |key, value|
			s = ":#{key} => "
			if value.is_a? String
				s << "\"#{value.to_s}\""
			else
				s << value.to_s
			end
			ret << s << ", "
		end
		'{ ' << ret.chomp(', ') << ' }'
	end
	
	# Override textilize feature
	def textilize(text) # overriding Rails method to remove hardbreaks
    return "" if text.blank?
    RedCloth.new(text).to_html
  end

  def textile_example
    render :partial => 'shared/textile_example'
  end

	# returns a formatted date	

	def d(aDate, zoned = false)
	  return '-' unless aDate
	  aDate = Timezone.get('America/Los_Angeles').utc_to_local(aDate) if zoned and aDate.is_a? DateTime
		aDate.strftime(FORMAT_DATE)
	end
	
	def D(aDate, zoned = false)
	  return '-' unless aDate
	  aDate = Timezone.get('America/Los_Angeles').utc_to_local(aDate) if zoned and aDate.is_a? DateTime
		aDate.strftime(FORMAT_BIGDATE)
	end
	
	def dm(aDate, zoned = false)
	  return '-' unless aDate
	  aDate = Timezone.get('America/Los_Angeles').utc_to_local(aDate) if zoned and aDate.is_a? DateTime
		aDate.strftime("%m/%Y")
	end
	
	# encodes a string in hex to obfuscate it to robots
	def hexencode(s)
	
  	string = ''
		for i in 0...s.length
			if s[i,1] =~ /\w/
				string << sprintf("&#%d;",s[i])
			else
				string << s[i,1]
			end
		end
		string
	
	end
	
	def cycle_stripes
	  cycle('alt0','alt1')
	end
	
	def classif(condition, string)
	  string if condition
	end
	
	def table_heading_row(columns)
	  content_tag('tr', columns.collect{|c| content_tag('th', c)}, :class=>'th')
	end
	
	def contract_status_graphic(contract)
	  case contract.contract_status
	  when Contract::STATUS_PROPOSED
	    image_tag('question.gif')
	  when Contract::STATUS_ACTIVE
	    image_tag('pencil.gif')
	  when Contract::STATUS_CLOSED
	    image_tag('cancel.gif')
	  end
	end
	
	def enrollment_status_graphic(enrollment)
	  case enrollment.enrollment_status
	  when Enrollment::STATUS_FINALIZED
	    case enrollment.completion_status
	    when Enrollment::COMPLETION_FULFILLED
	      return image_tag('check_f.gif')
	    when Enrollment::COMPLETION_CANCELED
	      return image_tag('cancel_f.gif')
	    end
	  when Enrollment::STATUS_PROPOSED
	    return image_tag('question.gif')
	  when Enrollment::STATUS_ENROLLED
	    return image_tag('pencil.gif')
	  when Enrollment::STATUS_CLOSED
	    case enrollment.completion_status
	    when Enrollment::COMPLETION_FULFILLED
	      return image_tag('check.gif')
	    when Enrollment::COMPLETION_CANCELED
	      return image_tag('cancel.gif')
	    end
	  end
	  raise ArgumentError, "No status graphic to match state!"
	end
	
	def credit_note(ca)
	  unless ca.note.blank?
			return [tag('br'),ca.note]
		else
			return ''
		end
	end
	
	
	def turnin_for assignment, turnins, missing = Turnin.new(:status => :missing)
	  turnins.detect(Proc.new{missing}){|t| t.assignment_id == assignment.id}
	end
	
	def blank_if_zero(value)
	  unless value=="0" || value == 0
	    value
	  else
	    ""
	  end
	end
	    
end
