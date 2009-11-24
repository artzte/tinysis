module AttendanceHelper
	
  def contract_id_field
    "<input type='hidden' id='contract_id' value='#{@contract.id}' />"
  end
end
