class ContractEalr < ActiveRecord::Base
  set_table_name "contract_ealrs"

  belongs_to :contract
  belongs_to :ealr

end
