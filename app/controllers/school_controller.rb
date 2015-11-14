class SchoolController < ApplicationController

helper :contract

before_filter Proc.new{|controller| controller.set_meta :tab1 => :school, :tab2 => :index}

public

	def index
	  set_meta :tab2 => :index, :title => 'Welcome'
	end
	
	def catalog
	  set_meta :tab2 => :catalog, :title => "Course Catalog"
    @facilitators = User.teachers
    @terms = Term.find(:all, :conditions => "school_year = #{coor_term.school_year}", :order => 'credit_date')

		filters = {:category_id => nil, :term_id => nil, :facilitator_id => nil}
		filters.keys.each do |k|
		  filters[k] = params[k].to_i unless params[k].blank? || params[k] == "-1"
		end
    @category_id = filters[:category_id]
    @term_id = filters[:term_id]
    @facilitator_id = filters[:facilitator_id]

		@courses = Contract.catalog(filters)
    @categories = Category.all_public
    @groups = @courses.group_by{|c| c.category_id}
	end
	
	def unknown_request
	  render :template => "shared/404", :layout => false, :status => 404
  end

  def boom 
    render :text => 1/0
	end

end
