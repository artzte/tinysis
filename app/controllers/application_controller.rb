# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# This one is derived from ::Base, the other ones are never.

class ApplicationController < ActionController::Base
  include SearchHelper
  include ExceptionNotification::Notifiable
	include LoginSystem
	
	layout "tiny"
	
  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::TextHelper
    
    def trunc_middle(str, count)
      excerpt = (count-3)/2

      reg = Regexp.new("^(.{#{excerpt}}).+(.{#{excerpt}})")
      str =~ reg

      return "#{$1}...#{$2}" if $1
      str
    end
  end

	before_filter :init_globals
	
  # prepend_before_filter :localize
  # 
  # def localize
  #   # determine locale and set other relevant stuff
  #   ActiveRecord::Base.date_format = "%Y-%m-%d"
  # end
  # 
protected

	def init_globals(action_tabs = nil)

		@user = get_user
    
    session[:school_year] ||= Setting.current_year

	  @this_month = Date.new(Date.today.year, Date.today.month)

	end
	
	def coor_term
	  @__coor_term ||= Term.coor(session[:school_year])
    @__coor_term
	end
	
	
public	
	# :tab1 => :maintab, :sub_tab => :subtab, :title => [], :javascripts => []
	def set_meta options = {}
	  @cur_tab ||= {}
	  @cur_tab[:tab1] = options[:tab1] if options.has_key? :tab1
	  @cur_tab[:tab2] = options[:tab2] if options.has_key? :tab2
	  
	  @head ||= {}
	  
	  if options.has_key? :title
	    @head[:title] = options[:title]
	    @head[:title] = @head[:title].join(' - ') if @head[:title].is_a? Array
	  end
	  
    if options.has_key? :javascripts
      @head[:javascripts] ||= []
      @head[:javascripts] << options[:javascripts] 
      @head[:javascripts] = @head[:javascripts].flatten.uniq
    end
  end
	hide_action :set_meta
	
protected
	# gets a contract either from an ID passed with the URL, or the contract
	# stored with the session. returns true if a contract was found, false
	# otherwise.
	
	def get_contract(the_id = nil)

		id = the_id || params[:contract_id] || params[:id] || session[:contract_id]
		return false if id.nil?
		
		@contract = Contract.find_by_id(id)
		return false unless @contract
		 
		@privs = @contract.privileges(@user)
		
		session[:contract_id] = @contract.id
		return true
	end
	
	# filter action that gets the session contract
	
	def get_contract_filter
	  get_contract
	  @tabtitle = @contract.name unless @contract.nil?
	  true
	end

	# clears the contract ID in the session and any contract instance variable
	def clear_contract
	  @contract = nil
	  session[:contract_id] = nil
  end
  
  def get_student

    id = (params[:id] || params[:student_id] || session[:student_id])
    unless id.nil?
      @student = User.find(id)
      @tabtitle = @student ? @student.full_name : ''
      session[:student_id] = @student.id
      @privs = @student.privileges(@user)

  		if @student.nil? or (@student.id != @user.id and @user.privilege < User::PRIVILEGE_STAFF)
  			redir_error(TinyException::SECURITYHACK, @user)
  			return false
  		end
    end
    true
  end

  def has_student?
    @student.nil? == false
  end
  
	# This method sets up the contract editing tabs; it is called with an ID 
	# and provides a tabbed editing interface for the contract object

	def redir_home(msg = nil)
		flash[:notice] = msg unless msg.nil?
		redirect_to home_path
	end

	def redir_login
	  
	  if request.xml_http_request?
	    render :update do |page|
	      page.redirect_to login_path
	    end
	  else
	    redirect_to login_path
    end
    
	end

	def redir_error(id, user)
		reset_tiny_sessionvars
		if request.xml_http_request?
  		render :update do |page|
  			page.alert TinyException::MESSAGES[id]
  			page.redirect_to home_path
  		end
		else
		  flash[:notice] = TinyException::MESSAGES[id]
		  redirect_to home_path
		end
	end
	
	def reset_tiny_sessionvars
	  save_flash = flash
	  reset_session
	  flash = save_flash
	end

	# make a date from a month start time and a day
	def make_date(date_params)
	  raise ArgumentException, "Date parameters nil or missing month or day value" if date_params.nil? or date_params["month"].nil? or date_params["day"].nil?
	  my = Time.at(date_params["month"].to_i).gmtime
	  day = date_params["day"].to_i
	  
	  Time.gm(my.year, my.month, day)
	end
	
	
  # debug helper
  
  def show_params
    render :update do |page|
      page.alert params.inspect
    end
  end
  
protected
  def d(aDate, zoned = false)
	  return '-' unless aDate
	  aDate = Timezone.get('America/Los_Angeles').utc_to_local(aDate) if zoned and aDate.is_a? DateTime
		aDate.strftime(FORMAT_DATE)
	end
	helper_method :d
  
end
