class CreateContracts < ActiveRecord::Migration

  def self.up
    create_table :contracts do |table|

			# name of the class or learning experience
      table.column :name, :string, :null => false
			table.column :category_id, :integer, :null => false

			# html based descriptions of the class
			table.column :learning_objectives, :text
			table.column :competencies, :text
			table.column :evaluation_methods, :text
			table.column :instructional_materials, :text

			# representation of the targeted credits
			# stored as a serialized hash
			table.column :credits, :text

			# the author or proposer of the class. this could be an instructor,
			# student, or other staff member
			table.column :facilitator_id, :integer, :null => false
			
			#creator /updator records
			table.column :creator_id, :integer, :null => false
			table.column :created_on, :datetime, :null => false
			table.column :updator_id, :integer, :null => false
			table.column :updated_on, :datetime, :null => false

			# in which term the class is running
			table.column :term_id, :integer, :null => false

			# where the class meets
			table.column :location, :string

			# when the class meets
			table.column :timeslots, :text	# stored as a serialized hash

			# whether open for enrollment
			table.column :enrolling, :boolean, :default => false, :null => false

			# whether viewable by "public", e.g. a class
			table.column :public, :boolean, :default => false, :null => false

			# status: proposed, active, completed				
			table.column :contract_status, :integer, :default =>  Contract::STATUS_PROPOSED, :null => false
    end
		
  end

  def self.down
		drop_table :contracts
  end
end
