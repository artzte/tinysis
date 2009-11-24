class CreditTransmittalBatch < ActiveRecord::Base
  
  has_many :credit_assignments, :include => [:contract_term, :credit]
  
  validates_presence_of :finalized_on
  validates_presence_of :finalized_by
  
  def self.batches_with_counts
    sql = []
    sql << 'SELECT credit_transmittal_batches.*, COUNT(credit_assignments.id) as credit_assignment_count FROM credit_transmittal_batches'
    sql << 'INNER JOIN credit_assignments WHERE credit_assignments.credit_transmittal_batch_id = credit_transmittal_batches.id'
    sql << 'GROUP BY credit_transmittal_batches.id'
    sql << 'ORDER BY credit_transmittal_batches.finalized_on DESC'
    
    CreditTransmittalBatch.find_by_sql(sql.join(' '))
  end
  
end

