desc 'Extract contract data for a given range of contract IDs'

# TM find ^(\w[^,]+),\s+(.+?\w)\s+(\d+).+?(\d+).+?(\d+).+?([MF]).+\n
#    repl $1,$2,$3,$4,$5,$6

task :import_students => :environment do
  
  ActiveRecord::Base.establish_connection
  
  puts "importing students"
  line = 0
  raise(ArgumentError, "failed to open students.csv") unless students = File.open(RAILS_ROOT + "/db/migrate/data/students.csv")
  
  students.each do |s|
    line += 1
    next if s.blank?
    next if line == 1
    # last_name,first_name,DistrictID,Sex,DOB,Grade,Coordinatorlast_name
    
    values = s.split(',')
    unless values.length == 7
      raise(ArgumentError, "CSV parse failed on line #{line} of students.csv:\nFound: #{s}\nNeeds: last_name,first_name,DistrictID,Sex,DOB,Grade,Coordinatorlast_name")
    end
    
    last_name = values[0]
    first_name = values[1]
    district_id = values[2]
    gender = values[3]
    birthdate = values[4]
    district_grade = values[5]
    coordinator = values[6]

    unless birthdate =~ /^(\d+)\/(\d+)\/(\d+)$/
      raise(ArgumentError, "Birthdate parse of #{birthdate} failed on line #{line} of students.csv:\n#{s}")
    end 

    puts values.join(":")
    month = $1.to_i
    day = $2.to_i
    year = $3.to_i+1900
    birthdate = Time.mktime(year, month, day)
    login = User.unique_login(last_name, first_name)
  
    user = User.new
    
    user.first_name= first_name
    user.last_name = last_name
    user.district_id = district_id
    user.district_grade = district_grade
    user.birthdate = birthdate
    user.login = login
    user.login_status = User::LOGIN_NONE
    user.privilege = User::PRIVILEGE_STUDENT
    user.user_status = User::STATUS_ACTIVE
    user.coordinator = User.find(:first, :conditions => ["last_name = '?' and privilege >= ?", coordinator, User::PRIVILEGE_STAFF])
    pass = User.random_password
    user.password = pass

    puts "Error saving user #{last_name}, #{first_name}; line #{line}; errors:\n#{user.errors.inspect}" if !user.save
  end
  students.close

end