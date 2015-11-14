module StatusHelper
  include SearchHelper
	include NoteHelper
	include CreditHelper

	def aca_options(current, coor_status = false)

	  options = [Status::STATUS_ACCEPTABLE, Status::STATUS_PARTICIPATING, Status::STATUS_UNACCEPTABLE]
		options -= [Status::STATUS_PARTICIPATING] if coor_status
		aca = options.collect{|s| [Status::STATUS_NAMES[s], s]}
	  options_for_select(aca, current)	

	end

	def att_options(current)
		att = [Status::STATUS_ACCEPTABLE, Status::STATUS_UNACCEPTABLE].collect{|s| [Status::STATUS_NAMES[s], s]}
	  options_for_select(att, current)	
	end  

	def status_text(status)
		return "Unreported" if status.nil?
		if status.attendance_status == Status::STATUS_ACCEPTABLE and status.academic_status == Status::STATUS_ACCEPTABLE
			stat = "Acceptable."
		end
		if status.attendance_status == Status::STATUS_UNACCEPTABLE
			stat = "Attendance issues."
		end
		if status.academic_status == Status::STATUS_UNACCEPTABLE
			stat = "Academic issues."
		end
		if status.attendance_status == Status::STATUS_UNACCEPTABLE and status.academic_status == Status::STATUS_UNACCEPTABLE
			stat = "Attendance and academic issues."
		end
		stat

	end

	def attendance_status_text(stats)
	  return nil if stats.empty?

	  messages = []
	  messages << pluralize(stats[:presents], 'appearance') if stats[:presents]
	  messages << pluralize(stats[:absences], 'absence') if stats[:absences]
	  messages << pluralize(stats[:tardies], 'late arrival') if stats[:tardies]
	  messages

	end

  def student_links(student)
    render :partial => "status/student_links", :locals => {:student => student}
  end

end
