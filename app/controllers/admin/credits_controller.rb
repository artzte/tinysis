class Admin::CreditsController < AdminBaseController
  
  before_filter :get_credit, :only => [:edit, :update, :destroy]
  before_filter :set_meta

protected  
  def get_credit
    @credit = Credit.find(params[:id])
  end
  
  def set_meta
    super :tab1 => :settings, :tab2 => :credits, :title => 'Settings - Credits'
  end
  
public
  def index
  	@credits = Credit.admin_credit_report
  end

  def new
    @credit = Credit.new
  end

  def create
    @credit = Credit.new params[:credit]
    if @credit.save
      flash[:notice] = "Thank you for creating #{@credit.course_name}."
      redirect_to credits_path
    else
      flash[:notice] = "Could not create the credit type. Please check the settings and try again."
      render :action => 'edit'
    end
  end

  def update
    if @credit.update_attributes params[:credit]
      flash[:notice] = "Thank you for updating #{@credit.course_name}."
      redirect_to credits_path
    else
      flash[:notice] = "Could not update the credit type. Please check the settings and try again."
      render :action => 'edit'
    end
  end

  def destroy
    
    raise "A credit without denormalized credit info is about to have its credit whacked" if CreditAssignment.find(:first, :conditions => ["(credit_id = ?) AND (enrollment_id IS NOT NULL) AND (credit_course_name IS NULL)", @credit.id])
    
    @credit.destroy
    flash[:notice] = "Thank you for deleting the credit type formerly known as #{@credit.course_name}."
    redirect_to credits_path
  end
  

end
