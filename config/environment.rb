# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
TinySIS::Application.initialize!

require 'monkey_patches'

ActionMailer::Base.raise_delivery_errors = true

class Date
  def end_of_month
    days = (Date.new(self.year, 12, 31) << (12-self.month)).day
    Date.new(self.year,self.month,days)
  end

  def beginning_of_month
    Date.new(self.year,self.month)
  end
end

