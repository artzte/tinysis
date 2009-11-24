class AccountController < ApplicationController

  helper 'admin/accounts'
  
  before_filter :login_required, :except => [:login, :reset]
  before_filter :login_meta, :only => [:login, :reset]
  
  filter_parameter_logging :password

protected
  def login_meta
    set_meta :tab1=> :school, :tab2 => :login, :title => 'Log In'
  end
  
public
  def login
    redir_home and return unless @user.nil?
    
    return unless request.method==:post
    
		# this is a backdoor for spoofing a user - the first login needs to
		# authenticate against the password and be a system admin, and
		# and the second name needs to be a valid login.
		if params[:user][:login] =~ /^(\w+)_as_(\w+)$/
			u = User.authenticate($1, params[:user][:password])
			s = User.find_by_login($2)
			if (u and s and u.admin?)
				u = s
			else
				u = nil
			end
		else
			u = User.authenticate(params[:user][:login], params[:user][:password])
		end

    if u
      session[:user_id] = u.id
      flash[:notice]  =  "Hi, #{u.given_name}, and welcome to tinySIS."
      if u.privilege>User::PRIVILEGE_STUDENT
        redirect_back_or_default url_for(:controller => 'status', :action => 'index')
      else
        redirect_back_or_default '/my'
      end
    else
      flash[:notice]   = "Could not match login name and/or password."
		end

  end
    
  def logout
    reset_tiny_sessionvars
    redir_home "You've been logged out."
  end
	
	def reset

	  return if request.method==:get
	  
		email = params[:user][:email]
		unless email =~ User::REGEX_EMAIL
			flash[:notice] = "Please enter a valid email address."
			return
		end
		
		u = User.authorized_email(email)
		if u.nil?
		  flash[:notice] = "We could not find an active account with that email address. Please contact the office if you need assistance."
			return				
		end
		
		password = u.reset_password

		UserMailer::deliver_password_reset(u, password)
		
	  flash[:notice] = "Your login ID and new password have been emailed to you. Please change your password after logging in."

		redirect_to login_path
		
	end
	
	def blackboard
	  set_meta :tab1 => :my, :title => "#{@user.full_name} &ndash; Blackboard"
	  render :text => 'coming soon', :layout => true
	end
	
	def edit
	  if @user.student?
	    set_meta :tab1 => :my, :tab2 => :account, :title => "#{@user.full_name} Settings"
    else
      set_meta :tab1 => :status, :tab2 => :account, :title => "#{@user.full_name} Settings"
    end 
    @account = User.find_by_id @user.id
  end
  
  def update
    @account = User.find_by_id @user.id
    if @account.update_from_params(params[:account], @user)
      flash[:notice] = 'Your settings were updated.'
      redirect_to my_account_path
    else
      flash[:notice] = 'Please update your entries and try again.'
      edit
      render :action => 'edit'
    end

  end

end;
