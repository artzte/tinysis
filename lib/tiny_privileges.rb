# A helper class to make it easier to define privilege objects
class TinyPrivileges

	def initialize(values = nil)
		@privs = {
				:create => false,		# user can create one
				:edit => false,			# user can edit it
				:change_settings => false, #user can change settings (User object only)
				:view => false,			# user can view it
				:browse => false,		# user can minimally browse it
				:view_students => false, # user can view cross-student listings 
				:create_note => false,	# user can add a note to it
				:edit_note => false,		# user can edit any note
				:view_note => false }		# user can view any note
		@privs.update(values) unless values.nil?
	end

	def grant_all
		@privs.each {|key, value| @privs[key] = true }
	end
	
	
	def[](priv)
		@privs[priv]
	end
	
	
	def[]=(priv, value)
		raise "Unknown privilege type" if !@privs.has_key?(priv)
		@privs[priv] = value	
	end

	# Return a hash describing privileges of the specified user
	# to manipulate child objects attached to this contract

	def TinyPrivileges.contract_child_object_privileges(user, theContract)

		# create a new privileges object with no rights
		p = TinyPrivileges.new

		# user and contract must be specified
		return p if user.nil?
		return p if theContract.nil?

		# an admin has full privileges
		return p.grant_all if user.admin?

		# a facilitator has full privileges
		
		return p.grant_all if theContract.facilitator == user
		
		##########################################
		# see if the user has an active enrollment role on the contract here
		
		enrollment = theContract.participant_enrollment(user)
		user_role = enrollment ? enrollment.role : nil

		##########################################
		# USER IS NOT ENROLLED
		# if no role, then check for staff privileges
		if user_role.nil?

			# staff members can view and do notes
			p[:browse] = 
			p[:view] = 
			p[:view_students] = 
			p[:create_note] = 
			p[:view_note] = (user.privilege == User::PRIVILEGE_STAFF)

			return p
		end

		##########################################
		# USER IS ENROLLED
		# FOR EDIT PRIVILEGES,
		# user must be the facilitator or instructor
		p[:create] = 
		p[:edit] = 
		p[:view_students] = (user_role >= Enrollment::ROLE_INSTRUCTOR)
		
		# FOR VIEW/BROWSE PRIVILEGES,
		# user must be an instructor or a supervisor or the enrolled student
		p[:browse] = 
		p[:view] = (	(user_role >= Enrollment::ROLE_INSTRUCTOR) or
									(user.id == enrollment.participant.id) )

		# FOR NOTE CREATION PRIVILEGES,
		# same as view privileges
		p[:create_note] = p[:view]
		p[:view_note] = p[:view]

		# edit note same as edit object
		p[:edit_note] = p[:edit]
		return p
	end
end
