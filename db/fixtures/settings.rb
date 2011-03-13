Setting.seed do |s|
  s.name = "current_year"
  s.value = Time.new.year
end


Setting.seed do |s|
  s.name = "reporting_base_month"
  s.value = 9
end

Setting.seed do |s|
  s.name = "reporting_end_month"
  s.value = 6
end

Setting.seed do |s|
  s.name = "new_contract_term_default"
  s.value = 1
end

