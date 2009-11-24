class AddTermReportingMonth < ActiveRecord::Migration
  def self.up
    
    add_column :terms, :credit_date, :datetime
		add_column :credit_assignments, :contract_term_id, :integer

    CreditAssignment.find(:all, :conditions => 'creditable_type = "User"').each do |ca|
      term = Term.find_by_name(ca.contract_term) || Term.find(:first)
      ca.contract_term_id = term.id
      ca.save
    end
    
    #parents = CreditAssignment.find(:all, :conditions => 'parent_credit_assignment_id is not null').collect{|ca| ca.parent_credit_assignment_id}.uniq.join(',')
    #CreditAssignment.find(:all, :conditions => "id in (#{parents})").each do |ca|
    #  ca.uncombine
    #end unless parents.empty?
    
    #CreditAssignment.find(:all, :conditions => 'district_finalize_approved is not null and district_finalize_approved = true').each do |ca|
    #  ca.update_attributes(:district_finalize_approved => false)
    #end

		remove_column :credit_assignments, :contract_year
		remove_column :credit_assignments, :contract_term
  end
  
  def self.down
		remove_column :terms, :credit_date
		add_column :credit_assignments, :contract_year, :integer
		add_column :credit_assignments, :contract_term, :string
		remove_column :credit_assignments, :contract_term_id

  end
end
