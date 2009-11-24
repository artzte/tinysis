class AssignmentController < ApplicationController
  
  include StudentReport
  
  helper :note, :contract, :status
  
	before_filter :login_required
	before_filter :get_contract, :only => [:index, :edit, :create, :update, :new, :destroy, :record, :feedback_edit, :feedback_update, :student, :report]
	before_filter :get_assignment, :only=>[:edit, :update, :destroy, :feedback_edit]
	before_filter :validate_editable, :only=>[:update, :destroy, :feedback_edit]
	before_filter :validate_viewable, :only=>[:edit]
	before_filter Proc.new{|controller| controller.set_meta :tab1 => :contracts, :tab2 => :assignments, :javascripts => :assignments}, :only => [:index, :new, :edit, :update, :create, :student, :report]
	before_filter :fix_due_date, :only => [:create, :update]
	
	AJAX_METHODS = [:expand, :expand_all]
	
	verify :xhr => true, :only => AJAX_METHODS

protected	
	def get_assignment
	  @assignment = @contract.assignments.find(params[:id])
	end
	
	def validate_editable
	  validate_permissions(:edit)
	end
	
	def validate_viewable
	  validate_permissions(:view)
	end
	
	def validate_permissions(permission)
	  if @assignment.new_record?
	    @privs = @contract.privileges(@user)
	  else
	    @privs = @assignment.privileges(@user)
	  end
		if !@privs[permission]
			redir_error(TinyException::NOPRIVILEGES, @user)
			return
		end
	end

public
  def index
    redirect_to contracts_path and return unless @contract

    set_meta :title => "#{@contract.name} - Assignments"
    
    @enrollments = @contract.enrollments.statusable true
    @assignments = @contract.assignments

    @turnin_missing = Turnin.new

    q = <<END
  	  SELECT turnins.*, notes.id IS NOT NULL AS has_note, UCASE(LEFT(turnins.status,1)) AS scode FROM turnins 
      INNER JOIN assignments ON turnins.assignment_id = assignments.id
      INNER JOIN enrollments ON turnins.enrollment_id = enrollments.id
      LEFT OUTER JOIN (SELECT notes.id, notable_id FROM notes WHERE notable_type = 'Turnin' GROUP BY notable_id) AS notes ON notes.notable_id = turnins.id
      WHERE assignments.contract_id = #{@contract.id}
END
  	@turnins = Turnin.find_by_sql(q).group_by{|t| t.enrollment_id}

    render :layout => 'tiny'
  end
  
  def report
    index
  end
  
  
  def student
    
    # check for valid contract and enrollment
    redir_error(TinyException::SECURITYHACK, @user) and return unless @contract
    
    @enrollment = @contract.enrollments.find_by_id(params[:id], :include => [:participant])
    
    redir_error(TinyException::SECURITYHACK, @user) and return unless @enrollment
    
    @student = @enrollment.participant
    @student_privs = @student.privileges(@user)
    
    redir_error(TinyException::SECURITYHACK, @user) and return unless @privs[:view] && @student_privs[:view]
    
    # make the turnins
	  @assignments = @contract.assignments
    @enrollment.turnins.make(@assignments) if @privs[:edit]
    @turnins = @enrollment.turnins.find(:all)
    
    # get the notes
    @turnin_notes = Note.notes_hash @enrollment.turnins
    
    set_meta :title => "#{help.truncate(@contract.name, :length=> 20)} - #{@student.full_name}"

  end
  

  def new
    set_meta :title => "#{@contract.name} - Assignments - New"

    @assignment = Assignment.new(:creator => @user, :contract => @contract)

		validate_editable
  end
  
  def create
		if !@privs[:edit]
			redir_error(TinyException::NOPRIVILEGES, @user)
			return
		end
		
		# on success, we just return success code and the JS redirects
    @assignment = @contract.assignments.create(params[:assignment])
		if @assignment.valid?
		  flash[:notice] = "Thanks for adding your assignment."
      redirect_to assignments_path(@contract)
    else
		  flash[:notice] = "Your assignment could not be added. Please fix the errors noted and try again."
      set_meta :title => "#{@contract.name} - Assignments - New"
      render :action => 'new'
    end
  end
  
  def edit
    set_meta :title => "#{@contract.name} - #{@assignment.name}"
    
  end
    
  def update

		if @assignment.update_attributes(params[:assignment])
		  flash[:notice] = "Your assignment has been updated."
      redirect_to assignments_path(@contract)
    else
      set_meta :title => "#{@contract.name} - #{@assignment.name.blank? ? 'Assignment' : @assignment.name}"
		  flash[:notice] = "Your assignment could not be updated. Please fix the errors noted and try again."
      render :action => 'edit'
    end
  end
  
  def record
    redir_error(TinyException::NOPRIVILEGES, @user) and return unless @privs[:edit]

    turnin = find_or_create_turnin(params)
    
    render :nothing => true
  end
  
  def feedback_edit
    @turnin = find_or_create_turnin(params)
    @enrollment = Enrollment.find_by_id(@turnin.enrollment_id, :include => :participant) 
    @notes = @turnin.notes
    render :layout => 'modalbox'
  end
  
  def feedback_update
    turnin = find_or_create_turnin
    render :text => turnin.status.to_s[0,1]
  end
  
protected
  def status_from_value value
    case value
    when 'M','m'
      return :missing
    when 'C','c'
      return :complete
    when 'I','i'
      return :incomplete
    when 'E','e'
      return :exceptional
    when 'L','l'
      return :late
    else
      return :missing
    end
  end
  
  def find_or_create_turnin params
    turnin = Turnin.find_by_assignment_id_and_enrollment_id(params[:id], params[:enrollment_id])
    if(turnin)
      turnin.update_attribute(:status, status_from_value(params[:value])) if params[:value]
    else
      turnin = Turnin.create!(:assignment_id => params[:id], :enrollment_id => params[:enrollment_id], :status => status_from_value(params[:value]))
    end
    turnin
  end
  
  
  def fix_due_date
    year = params[:assignment]['due_date(1i)'].to_i
    month = params[:assignment]['due_date(2i)'].to_i
    day = params[:assignment]['due_date(3i)'].to_i
    begin
      date = Date.new(year, month, day)
    rescue ArgumentError
      date = Date.new(year, month)
      date = Date.new(date.year, date.month, date.end_of_month.day)
    end
    params[:assignment]['due_date(1i)'] = date.year.to_s
    params[:assignment]['due_date(2i)'] = date.month.to_s
    params[:assignment]['due_date(3i)'] = date.day.to_s
  end
  
  
public
  
	# deletes an assignment and re-renders the assignment views
	def destroy
		@assignment.destroy

    flash[:notice] = "Your assignment has been deleted."
    
    redirect_to assignments_path(@contract)
	end
	
	def expand
	  @expand = true
	  render :partial => 'description', :object => @assignment
	end
	
	def expand_all
	  get_contract
	  @expand = true
    @assignments = @contract.assignments
	  render :partial => 'assignments_table'
	end
	
	DIMENSIONS = {
	  :print => {
      :width => 220,
      :height => 50,
      :background_color => '#ffffff',
      :name => {
        :size => 12,
	      :width => 200,
	      :height => 30,
	      :x => 5,
	      :y => 0,
        },
      :date => {
        :size => 11,
	      :width => 200,
	      :height => 20,
	      :x => 5,
	      :y => 25,
        }
	    },
	    
	  :screen => {
      :width => 98,
      :height => 40,
      :background_color => '#ffffcc',
      :name => {
        :size => 10,
	      :width => 100,
	      :height => 25,
	      :x => 5,
	      :y => 0,
        },
      :date => {
        :size => 9,
	      :width => 100,
	      :height => 10,
	      :x => 5,
	      :y => 25,
        }
	    }
	  }
	
  	require 'RMagick'
  	def header
  	  params[:filename] =~ Assignment::HEADER_GRAPHIC_FILTER
      @assignment = Assignment.find_by_id $1 if $1

      print = $2=='p'
      if print
        @o = DIMENSIONS[:print]
      else
        @o = DIMENSIONS[:screen]
      end
      
      render :nothing => true, :status => 404 unless @assignment

      path = @assignment.path_to_header_graphic($2=='p')
      font = File.join(RAILS_ROOT,'assets','fonts','LucidaGrande.ttf')
      
      if print
        mark = Magick::Image.new(@o[:width], @o[:height]) do 
          self.background_color = '#ffffff'
        end
      else
        mark = Magick::Image.new(@o[:width], @o[:height]) do 
          self.background_color = '#ffffcc'
        end
      end
      # common parameters
      gc = Magick::Draw.new
      gc.gravity = Magick::WestGravity
      gc.font_stretch = Magick::ExpandedStretch
      gc.font = font
      gc.fill = "Black"
      gc.stroke = "none"
      
      gc.pointsize = @o[:name][:size]
      if print
        text = @assignment.name
      else
        text = help.trunc_middle(@assignment.name, 18)
      end
      gc.annotate(mark, @o[:name][:width], @o[:name][:height], @o[:name][:x], @o[:name][:y], text)

      gc.pointsize = @o[:date][:size]
      gc.annotate(mark, @o[:date][:width], @o[:date][:height], @o[:date][:x], @o[:date][:y], @assignment.due_date.strftime("%d %B"))
      
      mark.rotate!(-90)

      mark.write(path)

      send_file(path, :type => 'image/gif', :disposition => 'inline', :stream => true)
  	end

end
