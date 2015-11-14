class Note < ActiveRecord::Base
	include StripTagsValidator

	belongs_to :notable, :polymorphic => true
	belongs_to :author, :foreign_key => 'creator_id', :class_name => 'User'

	PRIVILEGE_NONE = 0
	PRIVILEGE_VIEW = 1
	PRIVILEGE_EDIT = 2

	# returns the privilege level of the supplied user on this note.
	#

	# Admins have edit privilege.
	# The creator of the note has edit privilege.
	# Note-edit-enabled users of the parent object have edit privilege.
	#

	# Viewing privileges are different. A parent object sets the viewing
	# privilege policy for the notes that it contains. The assumption is that
	# the parent object will not render the note if the logged user doesn't
	# have viewing privileges. However, we are double-checking here... the
	# note won't should not get rendered for any reason if PRIVILEGE_NONE
	# is returned.

	def privileges(user, parent_priv = nil)
		if user.admin?
			return PRIVILEGE_EDIT
		end
		if self.creator_id.nil? && user.privilege >= User::PRIVILEGE_STAFF
		  return PRIVILEGE_EDIT
		end 
		if self.creator_id == user.id
			return PRIVILEGE_EDIT
		end

		parent_priv ||= self.notable.privileges(user)

		return PRIVILEGE_EDIT if parent_priv[:edit_note]
		return PRIVILEGE_VIEW if parent_priv[:view_note]
		return PRIVILEGE_NONE
	end

	def dom_id
		"view_note_#{id}"
	end

	def Note.notes_hash(coll)
    result = {}

    return result if coll.empty?

	  notes=Note.find(:all, :conditions => ["notable_type = ? and notable_id in (?)", coll.first.class.to_s, coll.collect{|c| c.id}], :include=>:author)
	  notes.each do |note|
	    result[note.notable_id] ||= []
	    result[note.notable_id] << note
	  end
	  result.default = []
	  return result
	end

end
