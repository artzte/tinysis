desc 'Extract contract data for a given range of contract IDs'

task :misassigned_credits => :environment do
  
  ActiveRecord::Base.establish_connection
  
  canceled = Enrollment.find(:all, :conditions => "completion_status = #{Enrollment::COMPLETION_CANCELED}")
  
  misassigned = 0
  canceled.each do |e|
    e.credit_assignments.each do |ca|
      match = CreditAssignment.find(:first, :conditions => "creditable_type = 'User' and creditable_id = #{e.participant_id} and contract_name = '#{e.contract.name.gsub("'", "''")}' and contract_term_id = #{e.contract.term_id}")
      match.destroy
    end
  end

end
