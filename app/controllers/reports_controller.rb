# This controller just serves reports -- it does data queries and renders CSV files
class ReportsController < ApplicationController
  include StudentReport
  include StudentsSearchHelper
  
  before_filter :page_meta
  before_filter :init_students_list
  
public
  def ale
    respond_to do |format|
      # paginated HTML
      format.html
        setup_page_variables @students, 50
        @data,@months = ale_data(@fp, @page_items)

      # CSV
      format.csv do
        logger.info "ale data pull"
        @data,@months = ale_data(@fp, @students)
        csv_string = FasterCSV.generate do |csv|
          csv << ["Student","Coordinator","Grade","Status","Active Date","Inactive Date"] + @months.collect{|m| m.strftime('%b')}
          @students.each do |student|
            statuses = @data[student.id] || []
            columns = [
                student.last_name_first,
                student.coordinator ? student.coordinator.last_name_f : 'Unassigned',
                student.district_grade,
                User::STATUS_NAMES[student.status][0..0],
                d(student.date_active),
                student.date_inactive ? d(student.date_inactive) : '',
              ] +
              @months.collect{|m| csv_month(student, statuses, m, @this_month)}.flatten
            csv << columns
          end
        end
        render :text => csv_string, :layout => false
      end
    end
  end
  
  def credits
    @students = students_find(@fp)
    credits_data(params)
  end
  
protected
  def init_students_list
    get_session_pager('student')
  	students_index_init

    @students = students_find(@fp)
  end

  def page_meta
    set_meta :tab1 => :students, :tab2 => :index
  end
  
  def csv_month(student, statuses, month, this_month)
    status = statuses.find{|s| s.month == month}
    if month > this_month
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
