module GraduationPlanHelper
  def extras(ca)
    [ca.contract_term.name, ca.contract_name, ca.contract_facilitator_name].select{|a| !a.blank?}.join(' / ')
  end
end
