module ReportsHelper
  include SearchHelper

  def csv_month_columns(student, statuses, month, this_month)
    status = statuses.find{|s| s.month == month}
    if month > @this_month
      ['-','-']
    elsif !student.was_active? month
      ['I','I']
    elsif status.nil?
      ['?','?']
    else
      [status.fte_hours, Status::STATUS_NAMES[status.academic_status][0..0]] 
    end 
  end
end
