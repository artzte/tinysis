require 'fastercsv'

# ^(\w[^,]+),\s+(.+?\w)\s+(\d+)\s+[MF]\s+\w+\s+\d\d/\d\d/\d\d\d\d\s+\d+\s+(\d+)\s+([\w*]+)\s*\n
# $1,$2,$3,$4,$5\n

desc 'Enroll a new batch of hooligans and de-enroll the ones who aren\'t there anymore'

task :merge_students => :environment do
  
  ActiveRecord::Base.establish_connection
  
  raise(ArgumentError, "specify FILE=filename") unless ENV['FILE']
  
  puts "merging students"
  
  coor_inactive = User.find(:first, :conditions => ["privilege = ? and last_name = 'Inactive'", User::PRIVILEGE_STAFF])
  coor_bucket = User.find(:first, :conditions => ["privilege = ? and last_name = 'Bucket'", User::PRIVILEGE_STAFF])
  
  # mark all students inactive first
  User.update_all(["status = ?, coordinator_id = ?", User::STATUS_INACTIVE, coor_inactive.id], ["privilege = ?", User::PRIVILEGE_STUDENT])
  User.update_all(["date_inactive = ?", Date.new(2009,7)], "date_inactive is null")

  coordinators = {
    '34' => ['Barth','Susan'],
    '46' => ['Brown','Sheri'],
    '35' => ['Cherniak','Debbie'],
    '33' => ['Croft','Adam'],
    '38' => ['Finnegan','Patty'],
    '45' => ['Franklin','Joleen'],
    '27' => ['George','Al'],
    '26' => ['Johnson','James'],
    '31' => ['Kosoglad','Karen'],
    '43' => ['Laird','Becky'],
    '41' => ['Batman','The Dark Knight'],
    '28' => ['Osborne','Barbara'],
    '0' => ['Park','Melissa'],
    'LL' => ['Stickler','Jay'],
    '29E' => ['Perry','Mark'],
    '47'  => ['Szwaja','Joseph'],
    '32' => ['Winet','Eyva'],
  }
  
  coordinators.each do |k,v|
    coor = User.find(:first, :conditions => ["privilege >= ? and last_name = ? and first_name = ?", User::PRIVILEGE_STAFF, v[0], v[1]])
    raise(ArgumentError, "could not find coor #{v}") unless coor
    coordinators[k] = coor
  end
  coordinators.default = coor_bucket
  
  line = 0
  raise(ArgumentError, "failed to open #{ENV['FILE']}") unless students = File.open(ENV['FILE'])
  
  FasterCSV.foreach(ENV['FILE']) do |s|
    line += 1
  	unless s.length == 5
  		raise(ArgumentError, "CSV parse failed on line #{line} of students.csv:\nFound: #{s.join(',')}\nNeeds: last_name,first_name,DistrictID,Grade,Homeroom")
  	end
  	
  	last_name = s[0].strip
  	first_name = s[1].strip
  	district_id = s[2].strip
  	district_grade = s[3].strip.to_i
  	homeroom = s[4].strip
  	
  	# try to find by district ID
  	
  	user = User.find_by_district_id district_id
    user ||= User.find_by_last_name_and_first_name last_name, first_name
  	
  	unless user
  	  user = User.new
  	  user.login = User.unique_login(last_name, first_name)
  	  user.password = User.random_password
  	  user.login_status = User::LOGIN_NONE
  	  user.privilege = User::PRIVILEGE_STUDENT
  	  
  	  # user active date should be day before first reporting month
  	  user.date_active = Date.new(2009,8,31)
  	end
  	
  	# set active new / existing students
	  user.last_name = last_name
	  user.first_name = first_name
	  user.district_id = district_id
	  user.district_grade = district_grade
	  user.status = User::STATUS_ACTIVE
	  user.date_inactive = nil
 	  
  	user.coordinator = coordinators[homeroom]
    puts "User #{last_name} line #{line} homeroom #{homeroom} into the bucket" if user.coordinator.last_name == "Bucket"
  	puts "Error saving user #{last_name}, #{first_name}; line #{line}; errors:\n#{user.errors.inspect}" if !user.save
  end

end