class CreditTransmittalBatch < ActiveRecord::Base
  
  has_many :credit_assignments
  
  validates_presence_of :finalized_on
  validates_presence_of :finalized_by
  
  APPROVED_CONDITIONS = "(credit_transmittal_batch_id IS NULL) AND (user_id IS NOT NULL) AND (district_finalize_approved = true) AND (parent_credit_assignment_id IS NULL)"
  
  def self.batches_with_counts
    sql = []
    sql << 'SELECT credit_transmittal_batches.*, COUNT(credit_assignments.id) as credit_assignment_count FROM credit_transmittal_batches'
    sql << 'LEFT JOIN credit_assignments ON credit_assignments.credit_transmittal_batch_id = credit_transmittal_batches.id'
    sql << 'GROUP BY credit_transmittal_batches.id'
    sql << 'ORDER BY credit_transmittal_batches.id DESC'
  
    CreditTransmittalBatch.find_by_sql(sql.join(' '))
  end
  
  def self.create_batch( user )
    count = CreditAssignment.count(:conditions => APPROVED_CONDITIONS)
    return nil if count==0

    batch = CreditTransmittalBatch.create!(:finalized_by => user.full_name, :finalized_on => Time.now.gmtime)
    
    CreditAssignment.update_all(["credit_transmittal_batch_id = ?", batch.id], APPROVED_CONDITIONS)

    batch.reload
    
    return batch
  end
  
  def self.credits_approved_for_transmittal

	  CreditAssignment.find(:all, :include => [:credit], :conditions => APPROVED_CONDITIONS)

	end

end

