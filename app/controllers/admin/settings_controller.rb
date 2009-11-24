class Admin::SettingsController < AdminBaseController

  before_filter :set_meta
  layout 'tiny', :only => :index
  
protected
  def set_meta
    super :tab1=>:settings, :tab2=>:index, :title => 'Settings - School Year'
  end
  
public
  def index
    @current_year = Setting.current_year
    @base_month = Setting.reporting_base_month
    @end_month = Setting.reporting_end_month
  end

  def update
    Setting.current_year = params[:date][:year]
    
    Setting.reporting_base_month = params[:date][:start_month]
    Setting.reporting_end_month = params[:date][:end_month]
    
    flash[:notice] = 'Thank you for updating the school year settings.'
    redirect_to settings_path
  end

end
