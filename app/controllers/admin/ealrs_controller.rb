class Admin::EalrsController < ApplicationController

  before_filter :set_meta
  before_filter :get_ealr, :except => [:index, :new, :create]
protected
  def set_meta
    super :tab1=> :settings, :tab2 => :ealrs, :title => 'Settings - EALRs'
  end

  def get_ealr
    @ealr = Ealr.find_by_id params[:id]
    unless @ealr
      flash[:notice] = "Could not find that EALR."
      redirect_to ealrs_path
    end
  end

public
  def index
    @categories = Ealr.categories
    @category = params[:category] if params[:category] && @categories.include?(params[:category])
  	@category ||= @categories.first
  	
  	@ealrs = Ealr.ealrs_for_category(@category)
  end

  def new
    params[:category] ||= Ealr.categories.first
    @ealr = Ealr.new :category => params[:category]
  end

  def create
    @ealr = Ealr.new params[:ealr]
    if @ealr.save
      flash[:notice] = 'Thank you for adding the EALR.'
      redirect_to ealrs_path(:category=>@ealr.category)
    else
      flash[:notice] = 'Please review the settings and try again.'
      render :action => 'new'
    end
  end

  def update
    if @ealr.update_attributes params[:ealr]
      flash[:notice] = 'Thank you for updating the EALR.'
      redirect_to ealrs_path(:category=>@ealr.category)
    else
      flash[:notice] = 'Please review the settings and try again.'
      render :action => 'edit'
    end
  end

  def destroy
    @ealr.destroy
    flash[:notice] = 'Thank you for deleting the EALR.'
    redirect_to ealrs_path :category => params[:category]
  end

end
