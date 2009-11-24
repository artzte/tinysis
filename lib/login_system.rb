require_dependency "user"

module LoginSystem 
  
  protected
  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user, privlevel)
    
    privlevel.nil? || privlevel <= user.privilege    
    
  end
  
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(user)
  # 
  def auth_required(privlevel = nil)
		u = get_user 
    if u and authorize?(u, privlevel)
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied
    return false 
  end
  
  def admin_required
    auth_required(User::PRIVILEGE_ADMIN)
  end
  
  def staff_required
    auth_required(User::PRIVILEGE_STAFF)
  end
  
  def login_required
    auth_required
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    if @user.nil?
			store_location
      redir_login
    else
      redir_error TinyException::SECURITYHACK, @user
    end
    false
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session[:return_to] = request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end

  def get_user
		return nil if session[:user_id].nil?

		User.find(session[:user_id])
  end
  
  def is_admin
     has_priv User::PRIVILEGE_ADMIN
  end
    
    
  def has_priv(priv)
    
    if @user.nil?
			return false
		end
    @user.privilege >= priv

  end
  
  def reset_login_sessionvars
    session[:return_to] = nil
    session[:user_id] = nil
  end
end