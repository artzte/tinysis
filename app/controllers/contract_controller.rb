class ContractController < ApplicationController
  helper :credit, :note, :search

	include ContractsSearchHelper

  PUBLIC_METHODS = [:index, :new, :create, :show, :roll, :participant]

  before_filter :login_required
  before_filter :get_contract_filter, :except => [:new]
  before_filter :contract_meta, :only => PUBLIC_METHODS
  before_filter :require_contract, :only => [:show, :roll, :participant]
  
  verify :xhr => true, :only => [:edit, :update, :cancel]

public

##################################################################
# homepage actions

	def index
	  contracts_index
	end

	def show
	  set_meta :title => @contract.name, :tab2 => :show

		if @privs.nil? or !@privs[:browse]
			redir_error(TinyException::SECURITYHACK, @user)
			return
		end
		
		@assignments = @contract.assignments
	end

	def edit
		if @contract.nil? || @privs.nil? or !@privs[:edit]
			redir_error(TinyException::SECURITYHACK, @user)
			return
		end
		
		@section = params[:section]
		
		render :layout => false
	end
	
	def cancel
		if @contract.nil? || @privs.nil? or !@privs[:edit]
			redir_error(TinyException::SECURITYHACK, @user)
			return
		end
		
		@section = params[:section]
		
		render :partial => "show_#{@section}"
	end


	def update
		
		@section = params[:section]

		if update_contract(@contract)
      @contract.reload
			render :partial => "show_#{@section}"
		else
		  flash[:notice] = TinyException::MESSAGES[TinyException::CONTRACTUPDATEFAILED]
		  render :action => 'edit'
		end
	
	end

	# Adds a new contract and redirects to the contract editor - this happens
	# via get / post 

	def new
	
		# clear the contract instance in the controller and in the session
    clear_contract
    
    set_meta :tab2=>:new
    
		# check for create privileges
		privs = Contract.privileges(@user)
		if privs[:create] == false
			redir_error(TinyException::NOPRIVILEGES, @user)
			return
		end

    # find the first "semester" term with nearest credit date as default term
		@contract = Contract.new :term => Setting.new_contract_term_default

  end
  
  def create
    
    set_meta :tab2 => :new
    
		# create a new contract
		@contract = Contract.new params[:contract]

		# record author
    @contract.creator = @user

		if update_contract(@contract) 
			flash[:notice] = "Thanks for creating the new contract."
			session[:contract_id] = @contract.id
			redirect_to contract_path @contract
		else
		  flash[:notice] = "Contract was not added."
		  render :action => 'new'
		end
	end
	
	def credits
	  
		redir_error(TinyException::NOPRIVILEGES, @user) and return unless @privs[:edit]
	  
	  set_meta :tab1 => :contracts, :tab2 => :enrollments

    render :layout => false
	end
	

##################################################################
# Contract setup methods

	def destroy
		contract = Contract.find(params[:id])
		privs = contract.privileges(@user)

    if(!privs[:edit])
      flash[:notice] = "You don't have privileges to delete the contract."
      redirect_to contracts_path and return
    end
		
		if contract.enrollments.count > 0 and !@user.admin?
		  flash[:notice] = "Admin privileges are required to delete a contract that has enrollments. Please remove all enrollments on the contract before deleting, or ask your admin to delete the contract."
		  redirect_to contracts_path and return
		end
		
    flash[:notice] = 'Thank you for deleting the contract "' + contract.name + '."'
		contract.destroy
		
		clear_contract

		redirect_to contracts_path

	end

##################################################################
# Timeslot / schedule Management
#
# New timeslots are added as DOM elements and then stored by the
# save procedure for the contract. The hard work is here... once
# the timeslot hash has been constructed it is stored as a hidden
# value in the form and then that hidden value is converted back
# to a hash and then serialized.

	# constructs a timeslot hash to store as a serialized yaml value
	# in the database
	#

	def add_timeslot
		valid = true
		notice=""
		
		tparams = params[:timeslot]

		# at least one weekly meeting day is required for a timeslot
		if tparams[:weekdays].nil?
			notice = "Please specify at least one meeting day for the class."
			render :update do |page|
				page.replace_html 'timeslot_form_notice', notice
			end
			return
		end

		# if custom timeslot not specified, store the timeslot
		# info from the canned list
		if tparams[:use_other]
			# store the custom values
			timeslot = ClassPeriod.new(tparams[:start_time][:hour]+':'+tparams[:start_time][:minute],
			                         tparams[:end_time][:hour]+':'+tparams[:end_time][:minute])
		else
		  timeslot = ClassPeriod.from_period_string(tparams[:period])
		end

		# store the weekdays
		a=[]
		tparams[:weekdays].each do |key, value|
			a << value.to_i
		end
		timeslot.weekdays = a

		# add the dom element to the page and close the timeslot form
		render :update do |page|
			page.insert_html :before, 'add_timeslot', :partial => "timeslot_line", :object => timeslot
			page.replace_html "add_timeslot", :partial => "timeslot_link"
		end
	end

	# open the form	

	def open_timeslot_form
		render :update do |page|
			page.replace_html "add_timeslot", :partial => "timeslot_form"
		end
	end

	# restore the open form link

	def open_timeslot_link
		render :update do |page|
			page.replace_html "add_timeslot", :partial => "timeslot_link"
		end
	end
	
	# copy a contract
	
	def copy
	  if @user.privilege < User::PRIVILEGE_STAFF
	    render :text => 'You do not have privileges for this action.', :status => 500
	    return
	  end
	  
	  @contract = Contract.find(params[:id])
    case request.method
    when :get
      render :template => 'contract/copy', :layout => false
      return
    when :post
      copy = @contract.copy(params[:contract])
      
      if copy and copy.valid?
        render :text => copy.id
        return
      else
        render :text => 'There is another contract with the same settings already in the system. Please change the settings so that your new contract will be unique.', :status => 500
        return
      end
    end
  end

protected

	# Saves a contract record. The order of update is significant...
	# pay attention to this when adding new values to save with the 
	# contract 

	def update_contract(contract)

		contract.term = Term.find(params[:contract][:term_id]) if params[:contract] && params[:contract][:term_id]
		
		if params[:activate] && params[:activate] == '1'
		  contract.contract_status = Contract::STATUS_ACTIVE
		end
		
		if params[:contract] && params[:contract][:facilitator_id]
		  contract.facilitator = User.find(params[:contract][:facilitator_id])
		else
		  contract.facilitator = @user.privilege >= User::PRIVILEGE_STAFF ? @user : User.unassigned
		end
		
		if params[:saved_timeslot]
  		contract.timeslots = []
  		params[:saved_timeslot].each do |k,v|
  			contract.timeslots << eval(v)
  		end
    end
    
    if params[:ealr]
      contract.ealrs.clear
      contract.ealrs << Ealr.find(:all, :conditions => ["id in (?)", params[:ealr].values.collect{|e| e.to_i}])
    end
    
		## SECOND we store the form parameters
		return contract.update_attributes(params[:contract])
	end
	

	def require_contract
	  unless @contract
	    flash[:notice] = "Can't find that contract."
	    redirect_to contracts_path and return 
	  end
	end
	
	def contract_meta
	  set_meta :javascripts => :contract, :tab1 => :contracts
	end
end
