class Admin::AccountsController < AdminBaseController
  
  before_filter :accounts_meta
  before_filter :get_account, :except => [:new,:index, :create]
  before_filter :init_fp, :only => [:new, :create]

protected
  
  def accounts_meta
    set_meta :tab1 => :admin, :tab2 => :accounts, :title => 'Accounts'
  end
  
  def get_account
	  @account = User.find(params[:id])
	  
	  init_fp
  end

  def init_fp
    @fp = {:n => params[:n], :p => params[:p], :pg => params[:pg], :c => params[:c]}
	end
	
public
  def index
  	get_session_pager('account')
  	
    conditions = []
    arguments = []
    
    init_account_params
    
    if @name_filter
      conditions << "((users.last_name like ?) or (users.first_name like ?) or (users.nickname like ?))"
      3.times{ arguments << "%#{@name_filter}%"}
    end
    
    case @coor_filter
    when 0
      conditions << "(users.coordinator_id is null or users.coordinator_id = 0)"
    when -1
    else
      conditions << "(users.coordinator_id = ?)"
      arguments << @coor_filter
    end
    
    case @priv_filter
    when User::PRIVILEGE_NONE
    when User::PRIVILEGE_STUDENT
      conditions << "(users.privilege = ?)"
      arguments << @priv_filter
    when User::PRIVILEGE_STAFF, User::PRIVILEGE_ADMIN
      conditions << "(users.privilege >= ?)"
      arguments << @priv_filter
    end
    
    case @status_filter
    when 0
    when User::STATUS_ACTIVE,User::STATUS_INACTIVE
      conditions << "(users.status = ?)"
      arguments << @status_filter
    end
    
    if conditions.empty?
      cond = nil
    else
      cond = [conditions.join(' and ')]+arguments
    end

    @accounts = User.find(:all, :include => [:coordinator], :conditions => cond, :order => 'users.last_name, users.first_name')
  	
  	setup_page_variables @accounts, 20
  	
    @fp = {:n => @name_filter, :p => @priv_filter, :s => @status_filter, :pg => @page, :c=> @coor_filter}
    
  	store_session_pager('account')
  end

  def edit
	end
  
  def new
	  @account = User.new
  end

  def create
	  @account = User.new
	  if @account.update_from_params params[:account], @user
	    flash[:notice] = "Thank you for updating account settings for #{@account.full_name}."
	    redirect_to accounts_path(@fp)
	  else
	    flash[:notice] = "Please update the settings and try again."
	    render :action => 'new'
	  end
  end

  def update
	  if @account.update_from_params params[:account], @user
	    flash[:notice] = "Thank you for updating account settings for #{@account.full_name}."
	    redirect_to accounts_path(@fp)
	  else
	    flash[:notice] = "Please update the settings and try again."
	    render :action => 'edit'
	  end
  end

  def destroy
    # BUGBUG
    raise ArgumentError, "Insufficient security measures here!!!"
    user = User.find(params[:id])
    user.destroy
    
    
	  @fp = {:n => params[:n], :p => params[:p], :pg => params[:pg], :c => params[:c]}
	  flash[:notice] = 'Account deleted'
	  
    redirect_to url_for({:action => 'account'}.update(@fp))
  end

  def init_account_params
    
    unless params[:n].blank?
      @name_filter = params[:n]
    end
    
    # privilege
  	if params[:p].blank?
  	  @priv_filter = @fp[:p] || 0
  	else
  	  @priv_filter = params[:p].to_i
  	end
  	
    # coor
  	if params[:c].blank?
  	  @coor_filter = @fp[:c] || -1
  	else
  	  @coor_filter = params[:c].to_i
  	end
  	
    # status
  	if params[:s].blank?
  	  @status_filter = @fp[:s] || 0
  	else
  	  @status_filter = params[:s].to_i
  	end
  	
  	# if selections changed, reset the pager variable to 1
  	if @priv_filter != @fp[:p] or @name_filter != @fp[:n] or @coor_filter != @fp[:c] or @status_filter != @fp[:s]
  	  @page = 1
  	end

  end
end

