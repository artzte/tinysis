class Admin::CategoriesController < AdminBaseController

  before_filter :get_category, :only => [:edit, :update, :destroy, :assign_group]
  before_filter :set_meta

  layout 'tiny', :only => :index

protected  
  def get_category
    @category = Category.find(params[:id])
  end

  def set_meta
    super :tab1 => :settings, :tab2 => :categories, :title => 'Settings - Categories'
  end

public
  def index
    @categories = Category.all
    @groups = @categories.group_by{|c| c.sequence}
  end

  def new
    @category = Category.new :sequence => 1
  end

  def edit
  end

  def create
    @category = Category.new(params[:category])
    if @category.save
  		flash[:notice] = "Thank you for adding the #{@category.name} category."
  		redirect_to categories_path
  	else
  	  flash[:notice] = "Could not update the category. Please review the settings and try again."
  	  render :action => 'edit'
  	end
  end

  def update
    if @category.update_attributes(params[:category])
  		flash[:notice] = "Thank you for updating the #{@category.name} category."
  		redirect_to categories_path
  	else
  	  flash[:notice] = "Could not update the category. Please review the settings and try again."
  	  render :action => 'edit'
  	end
  end

	def destroy
		unless @category.contracts.empty?
      flash[:notice] = 'Category has contracts assigned to it and cannot be deleted.'
    else
      @category.destroy
      flash[:notice] = 'Thank you for updating the category'
		end
		redirect_to categories_path
	end

	def assign_group
    @category.update_attribute(:sequence, params[:group])
    render_update_result
	end

	def sort
	  # update all sequences to one-plus so we can then update them to the new
	  # sequences
	  Category.update_all('sequence = (sequence+1)')

	  params[:contract_categories].each_with_index do |g,i|
	    old_seq = g.to_i+1
	    Category.update_all "sequence = #{(i+1)*100}", "sequence = #{old_seq}"
	  end
    render_update_result
	end

private
  def render_update_result category = nil
    @categories = Category.all
    @groups = @categories.group_by{|c| c.sequence}

    render :partial => 'index'
  end

end
