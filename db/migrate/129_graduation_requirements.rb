class GraduationRequirements < ActiveRecord::Migration

  def self.up

    create_table :graduation_plans do |t|
      t.references :user
      t.string :class_of, :length => 4
    end
    
    create_table :graduation_plan_requirements do |t|
      t.string :name, :null => false
      t.text :notes
      t.integer :position, :default => 0
      t.integer :parent_id
      t.enum :requirement_type, :limit => GraduationPlanRequirement::REQUIREMENT_TYPES, :default => GraduationPlanRequirement::REQUIREMENT_TYPES.first, :null => false
     end
    add_index :graduation_plan_requirements, :parent_id
    add_index :graduation_plan_requirements, :requirement_type
    
    create_table :graduation_plan_mappings do |t|
      t.references :graduation_plan, :null => false
      t.references :credit_assignment
      t.references :graduation_plan_requirement, :null => false
      
      t.string :name
      t.date :date_completed
      t.integer :quantity, :default => 0
    end
    add_index :graduation_plan_mappings, :graduation_plan_id
    add_index :graduation_plan_mappings, :credit_assignment_id
    add_index :graduation_plan_mappings, :graduation_plan_requirement_id

  end


  def self.down
    drop_table :graduation_plans
    drop_table :graduation_plan_requirements
    drop_table :graduation_plan_mappings
  end
  
end