class Assignment < ActiveRecord::Base
	include StripTagsValidator

	belongs_to :contract
	has_many :notes, :as => :notable, :dependent => :destroy

	has_many :turnins, :include => [:enrollment, {:enrollment => :participant}, :notes], :order => "users.last_name, users.first_name", :dependent => :destroy

	validates_presence_of :name, :due_date
	validates_numericality_of :weighting, :less_than => 256, :greater_than => 0, :message => "must be a number from 1-255"
	
	belongs_to :creator, :foreign_key => 'creator_id', :class_name => 'User'
	
	acts_as_textiled :description
	
	# Return a hash describing privileges of the specified user
	# on this assignment

	def privileges(user)
		return TinyPrivileges.contract_child_object_privileges(user, contract)
	end
	
	def before_update
	  # kill the screen header tile
	  begin
	    File.delete(path_to_header_graphic)
    rescue
    end
    # kill the print header tile
	  begin
	    File.delete(path_to_header_graphic(true))
    rescue
    end
	end
	
	HEADER_GRAPHIC_FILTER = /^ah_(\d+)(p?)\.gif$/
	def path_to_header_graphic(print=false)
	  fn = "ah_#{self.id}"
	  fn << 'p' if print
	  File.join(RAILS_ROOT,'public','assets','gradesheet',"#{fn}.gif")
  end
  
end
