class AddFinalizedCreditAssignmentDenormalizationFields < ActiveRecord::Migration

  include ForeignKeys
  
  def self.up
    
    add_column :credit_assignments, :user_id, :integer
    add_column :credit_assignments, :contract_id, :integer
    
    change_column :credit_assignments, :credit_id, :integer, :null => true
    
    add_column :credit_assignments, :credit_course_name, :string
    add_column :credit_assignments, :credit_course_id, :string

    add_index "credit_assignments", ["user_id"], :name => "index_credit_assignments_on_user_id"
    add_index "credit_assignments", ["contract_id"], :name => "index_credit_assignments_on_contract_id"
    
    add_foreign_key_constraint :credit_assignments, :user_id, :users, :id, :on_delete => :restrict
    add_foreign_key_constraint :credit_assignments, :contract_id, :contracts, :id, :on_delete => :set_null
    add_foreign_key_constraint :credit_assignments, :credit_id, :credits, :id, :on_delete => :set_null
    
    # appears that at least one contract, and its enrollments, might be been trashed, leaving stray enrollment ids
    ActiveRecord::Base.connection.execute %Q{
      UPDATE credit_assignments ca 
      LEFT OUTER JOIN enrollments ON ca.enrollment_id = enrollments.id
      SET ca.enrollment_id = null
      WHERE ca.enrollment_id IS NOT NULL AND enrollments.id IS NULL
    }
    
    add_foreign_key_constraint :credit_assignments, :enrollment_id, :enrollments, :id, :on_delete => :cascade

    CreditAssignment.update_all("contract_id = creditable_id", "creditable_type = 'Contract'")
    CreditAssignment.update_all("enrollment_id = creditable_id", "creditable_type = 'Enrollment'")
    CreditAssignment.update_all("user_id = creditable_id", "creditable_type = 'User'")
    
    # move contract info over for finalized credits
    CreditAssignment.find_in_batches(:conditions => "enrollment_finalized_on IS NOT NULL AND creditable_type = 'Enrollment'") do |group|
      group.each do |ca|
        credit = ca.credit
        enrollment = ca.enrollment
        contract = ca.enrollment.contract
        facilitator = contract.facilitator
        if credit && enrollment && contract && facilitator
          ca.contract_name = contract.name if ca.contract_name.blank?
          ca.contract_facilitator_name = facilitator.last_name_first if ca.contract_facilitator_name.blank?
          ca.contract_facilitator_id = facilitator.id if ca.contract_facilitator_id.blank?
          ca.contract_term_id = contract.term_id if ca.contract_term_id.blank?
          ca.credit_course_name = credit.course_name if ca.credit_course_name.blank?
          ca.credit_course_id = credit.course_id if ca.credit_course_id.blank?
        else
          raise "whoops"
        end
      end

    end

    # move course name and id over for approved credits
    CreditAssignment.find_in_batches(:conditions => "creditable_type = 'User' AND district_finalize_approved") do |group|

      # move over the credit course name and id
      group.each do |ca|
        credit = ca.credit
        if credit
          ca.update_attributes(:credit_course_name => credit.course_name, :credit_course_id => credit.course_id)
        else
          raise "whoops"
        end
      end

    end
    
    remove_index :credit_assignments, :name => :index_credit_assignments_on_creditable
    remove_column :credit_assignments, :creditable_type
    remove_column :credit_assignments, :creditable_id
    
  end

  def self.down
    
  end
  
end