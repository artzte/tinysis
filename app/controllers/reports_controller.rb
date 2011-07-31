# This controller just serves reports -- it does data queries and renders CSV files
class ReportsController < ApplicationController
  include StudentReport
  include StudentsSearchHelper
  
  before_filter :page_meta
  
public
  def ale
    # parse the params list and populate the @fp instance variable
    students_index_init
    @students = students_find(@fp)
    @data,@months = ale_data(@fp, @students)
  end
  
  def credits
    credits_data(params)
  end
  
protected
  def page_meta
    set_meta :tab1 => :students, :tab2 => :index
  end
  
end
