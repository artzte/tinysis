class Admin::TermsController < AdminBaseController

  before_filter :set_meta
  before_filter :get_term, :only => [:edit, :show, :update, :destroy]

protected
  def get_term
    @term = Term.find(params[:id])
    unless @term
      flash[:notice] = "Could not find that term."
      redirect_to terms_path
    end
  end
  
  def set_meta
    super :tab1 => :settings, :tab2 => :terms, :title => 'Settings - Terms'
  end

public
  def index
		@terms = Term.all
		@base_month = Setting.reporting_base_month
  end
  
  def edit
  end

  def new
    @term = Term.new(:months => [], :school_year => Setting.current_year)
  end

  def create
    @term = Term.new(params[:term])
    @term.set_dates params[:term][:school_year], params[:month] ? params[:month].values : []
    if @term.save
      flash[:notice] = 'Thank you for adding the term.'
      redirect_to terms_path
    else
      render :action => 'new'
    end
  end

  def update
    @term.set_dates params[:term][:school_year], params[:month] ? params[:month].values : []
    if @term.update_attributes(params[:term])
      flash[:notice] = 'Thank you for updating the term.'
      redirect_to terms_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    @term.destroy
    flash[:notice] = "Thank you for deleting the term."
    redirect_to terms_path
  end
end
# 
# 
# @base_month = Setting.reporting_base_month
# if params[:id]
#   @term = Term.find(params[:id])
# else
#   @term = Term.new(:months => [], :school_year => Setting.current_year)
# end
# 
# case request.method
# when :post
#   @term.set_dates params[:term][:school_year], params[:month].values
#   if @term.update_attributes(params[:term])
#     return render_terms
#   else
#     render :text => 'You did not completely fill out the form', :status => 500 and return
#   end
# when :get
#   render :layout => false
#   return
# end  
