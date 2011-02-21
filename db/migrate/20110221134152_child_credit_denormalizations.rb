class ChildCreditDenormalizations < ActiveRecord::Migration
  def self.up
    
    batch = 1
    
    CreditAssignment.find_in_batches(:joins => 'inner join credit_assignments pca on credit_assignments.parent_credit_assignment_id = pca.id', :group => 'credit_assignments.id', :conditions => 'pca.district_finalize_approved_by is not null') do |credit_assignments|
      
      puts "Batch #{batch}"
      batch += 1

      credit_assignments.each do |ca| 
        ca = CreditAssignment.find(ca.id, :include => :credit)
        
        credit = ca.credit
        
        raise "whoops" unless credit
        ca.update_attributes :credit_course_name => credit.course_name, :credit_course_id => credit.course_id
      end

    end
  end

  def self.down
  end
end
