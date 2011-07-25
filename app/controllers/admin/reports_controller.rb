class Admin::ReportsController < AdminBaseController
  before_filter :set_meta

protected  
  def set_meta
    super :tab1 => :admin, :tab2 => :reports, :title => 'Admin Reports'
  end
  
public
  def index
  end
  
end
