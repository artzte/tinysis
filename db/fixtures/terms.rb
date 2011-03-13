Term.seed do |s|
  school_year = Time.new.year
  s.name = "Test"
  s.school_year = school_year
  s.active = true
  s.months = (9..12).collect{|m| Date.new(school_year, m, 1)} + (1..6).collect{|m| Date.new(school_year, m, 1)}
end