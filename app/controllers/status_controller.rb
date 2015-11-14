
class StatusController < ApplicationController

  include ContractsSearchHelper
  include StudentReport

  before_filter :login_required
	before_filter Proc.new{|controller| controller.set_meta(:tab1 => :status)}, :only => [:index, :contract, :coor, :contract_detail, :coor_detail, :contract_report, :coor_report]
	before_filter Proc.new{|controller| controller.set_meta(:tab2 => :coor)}, :only => [:coor, :coor_detail, :coor_report]
	before_filter Proc.new{|controller| controller.set_meta(:tab2 => :contract)}, :only => [:contract, :contract_detail, :contract_report]

##################################################################
# Layout setup for this controller

protected

	# tab setup for this controller
	TAB_BAR = 	
		[
			{ :title => "Home", :action => "index", :privilege => User::PRIVILEGE_STUDENT },
			{ :title => "Contract Status", :action => ["contract", "contract_detail", "contract_report"], :privilege => User::PRIVILEGE_STAFF},
			{ :title => "COOR Status", :action => ["coor", "coor_detail", "coor_report"], :privilege => User::PRIVILEGE_STAFF},
		]

	def has_contract?(tab)

	  @tabtitle = @contract.name unless @contract.nil?

	  @contract 
	end

	# this is called by the contracts_index function

	def init_contract_filters

	  statusable = Category.statusable
	  if statusable.length == 0
	    @conditions << "(true = false)"
	  else
	    @conditions << "(category_id in (#{Category.statusable.collect{|c|c.id}.join(',')}))"
    end
	end

public

##################################################################
# homepage actions

  def index

    contracts_index

    @coordinatees = @user.coordinatees_current

    store_session_pager('contract')

	  set_meta :tab2 => :index, :title => 'Home'
  end

  # Parameters: {"c"=>"1", "action"=>"contract", "f"=>"5", "controller"=>"status", "g"=>"-1", "t"=>"-2006"}
	def contract

	  contracts_index_init

    @fp = {:c=>@closed, :t=>@term, :f=>@facilitator, :g=>@category, :pg=>@page}

	  options = {}
	  options[:category_id] = @category unless @category == -1
	  options[:closed] = 1 if @closed == 1
	  options[:facilitator_id] = @facilitator unless @facilitator == -1

	  if @term > 1
	    options[:term_id] = @term
	  elsif @term == -1
	    options[:school_year] = Setting.current_year
	  else
	    options[:school_year] = @term*-1
	  end

    @staff = @facilitator == -1 ? @user : User.find(@facilitator)

	  @report = Status.contracts_months_missing(options)
	  @contracts = @report[:contracts]

	  set_meta :title => 'Contract Status'

	end

	def coor

	  @term = coor_term
	  @months = @term.months
	  @fp = {}
	  @report = Status.coor_months_missing({:coor_term => @term})
	  @coordinators = @report[:coordinators] || []

	  set_meta :title => 'COOR Status'

	end

	def contract_detail

	  get_contract_filter

	  @fp = {:c => params[:c], :t => params[:t], :f => params[:f], :g => params[:g], :pg => params[:pg]}

	  @students = @contract.enrollments.statusable
	  @months = @contract.statusable_months

	  set_meta :title => ['Contract Status', @contract.name]

	end

	def coor_detail
	  @coor = User.find(params[:id])
	  @fp = {}
	  @term = coor_term
	  @students = @coor.coordinatees_current(@term)
	  @months = @term.months

	  set_meta :title => "#{@coor.last_name} COOR"
	end

	def contract_report

		@enrollment = Enrollment.find(params[:id], :include => [:contract, :participant])
		@student = @enrollment.participant

		@statusable_months = @enrollment.contract.statusable_months.sort{|a,b| b<=>a}
		@statusable_months.delete_if{|m| !@student.was_active?(m) || m>@this_month}

		# if month set explicitly from request, use that month; if not, set it to current
		# month if current month is statusable
		if params[:m] and params[:m] =~ REG_PARSE_DATE
		  month = Date.parse(params[:m])
		  @month = month if @statusable_months.include? month
		else
		  @month = @this_month if @statusable_months.include? @this_month
		end

		@privs = @enrollment.privileges(@user)

		@enrollment.statuses.make(@month, @user) if @month && @privs[:edit]

	  # hash of statuses by month
	  @statuses = Hash[*@enrollment.statuses.collect{|s| [s.month, s]}.flatten]

    @status_notes = Note.notes_hash(@enrollment.statuses)

	  @collection = @enrollment.contract.enrollments.statusable(true)
	  @index = @collection.index(@enrollment)

	  set_meta :title => [@contract_name, @student.last_name], :tab2 => :contract, :javascripts => :assignments

	end

	def coor_report

		@student = User.find(params[:id], :include => :coordinator)
		@coor = @student.coordinator
		@privs = @student.privileges(@user)

    # Figure out which month we are trying to report on - and make sure it is
    # one of the months that student has been active. Allow error out with no
    # month / default status assigned if the parameter passed was crap

		@month = Date.parse(params[:m]) if params[:m] && params[:m] =~ REG_PARSE_DATE
		@month = nil if @month.nil? || !@student.was_active?(@month)

		@student.statuses.make(@month, @user) if @month && @privs[:edit]

    # set up instance variables for the coor report
		setup_coor_report :month => @month, :editable => @privs[:edit]

	  @collection = @coor.coordinatees_current
	  @index = @collection.index(@student)

	  set_meta :title => ["#{@coor.last_name} COOR", @student.last_name]

	end

	def enrollment_details
	  @enrollment = Enrollment.find(params[:id])
	  render :nothing => true and return unless @enrollment.privileges(@user)[:view]

	  @absences = @enrollment.absences
	  @turnins = @enrollment.turnins

	  render :layout => false
	end  

	def update_status

		status = Status.find(params[:id])
		render :nothing => true, :status => HTTP_STATUS_FORBIDDEN and return unless status
		privs = status.statusable.privileges(@user)
		render :nothing => true, :status => HTTP_STATUS_FORBIDDEN and return unless privs[:edit]
		status.update_attributes!(params[:status])
    render :nothing => true
	end

end
