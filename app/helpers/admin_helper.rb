module AdminHelper
  include SearchHelper
  include NoteHelper

	def years_options
		cur_year = Time.now.gmtime.year
		years_list = []
		[-2,-1,0,1,2].each do |i|
			year = cur_year + i
			years_list << [ year.to_s, year ]
		end
		years_list
	end
	
end
