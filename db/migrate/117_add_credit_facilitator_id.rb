class AddCreditFacilitatorId < ActiveRecord::Migration
  def self.up
  
  	add_column :credit_assignments, :contract_facilitator_id, :integer
    rename_column :credit_assignments, :contract_facilitator, :contract_facilitator_name
    users = User.find(:all).group_by{|u| u.lastname_first}
    CreditAssignment.find(:all, :conditions => 'creditable_type = "User"').each do |ca|
      if ca.enrollment
        fac_id = ca.enrollment.contract.facilitator_id unless ca.enrollment.nil?
        ca.update_attribute(:contract_facilitator_id, fac_id)
      elsif users[ca.contract_facilitator_name]
        ca.update_attribute(:contract_facilitator_id, users[ca.contract_facilitator_name].id)
      else
        puts ca.inspect
      end
    end
  
  end

  def self.down
  	remove_column :credit_assignments, :contract_facilitator_id
    rename_column :credit_assignments, :contract_facilitator_name, :contract_facilitator
  end
end
