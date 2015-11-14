class Setting < ActiveRecord::Base

	def Setting.periods=(p)
	
		setting = Setting.find_by_name("periods")
		if setting.nil? 
			setting = Setting.create(:name => "periods")
		end
		
		setting.update_attribute(:value, Marshal.dump(p))
		
		p		
	
	end
	
	def Setting.periods
	
		setting = Setting.find_by_name("periods")
		return [{}] if setting.nil?
		# what the hell is this?
		ClassPeriod.new
		Marshal.load(setting.value)
	
	end
	
	def Setting.set_integer(name, value)
	
		setting = Setting.find_by_name(name)
		if setting.nil? 
			setting = Setting.create(:name => name, :value => value.to_i)
		else
			setting.update_attribute(:value, value.to_i)
		end
		
		setting.value.to_i
	
	end
	
	def Setting.current_year=(year)
		set_integer("current_year", year)
		year
	
	end
	
	
	def Setting.school_years
	  Term.find(:all, :select => 'school_year').collect{|t| t.school_year}.uniq
	end
	
	def Setting.current_year
	
		setting = Setting.find_by_name("current_year")
		return nil if setting.nil? 
		
		setting.value.to_i
	
	end
	
	def Setting.reporting_base_month=(month)
	  raise ArgumentError, "Bad reporting base month value" if month.to_i <=0 or month.to_i > 12
	  set_integer("reporting_base_month", month)
	  month
	end
	
	
	
	
	def Setting.reporting_base_month
	  setting = Setting.find_by_name("reporting_base_month")
	  return 0 if setting.nil?
	  setting.value.to_i
	end
	
	def Setting.reporting_end_month=(month)
	  raise ArgumentError, "Bad reporting end month value" if month.to_i <=0 or month.to_i > 12
	  set_integer("reporting_end_month", month)
	  month
	end
	
	
	def Setting.reporting_end_month
	  setting = Setting.find_by_name("reporting_end_month")
	  return 0 if setting.nil?
	  setting.value.to_i
	end
	
	def Setting.new_contract_term_default=(term_id)
	  term = Term.find(term_id.to_i)
	  raise ArgumentError, "Bad term id" unless 
	  set_integer("new_contract_term_default", term_id.to_i)
	  term
	end
	
	def Setting.new_contract_term_default
	  setting = Setting.find_by_name("new_contract_term_default")
	  term = Term.find(setting.value.to_i) if setting
	  unless term
	    return Term.find(:first, :conditions => 'name LIKE "%semester%"', :order => 'school_year DESC, credit_date ASC')
	  else
	    return term
	  end
	end

end
