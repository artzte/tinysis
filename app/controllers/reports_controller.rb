# This controller just serves reports -- it does data queries and renders CSV files
class ReportsController < ApplicationController
  include StudentReport
  
public
  def ale
    ale_data(params)
  end
  
  def credits
    credits_data(params)
  end
  
  
  
end
