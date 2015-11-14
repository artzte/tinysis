desc 'Extract contract data for a given range of contract IDs'

task :set_schedules => :environment do
  ActiveRecord::Base.establish_connection
  Setting.reporting_end_month = 6
  Setting.reporting_base_month = 9
  
  term = Term.find_by_name('COOR/2006')
  term.set_dates(2006, [0,1,2,3,4,5,6,7,8])
  term.save
  term = Term.find_by_name('Fall 2006')
  term.set_dates(2006, [0,1,2,3,4])
  term.save
  term = Term.find_by_name('Spring 2007')
  term.set_dates(2006, [5,6,7,8,9])
  term.save
end

task :set_coordinators => :environment do
  
  ActiveRecord::Base.establish_connection
  
  # the first process sets the coordinator field on the user records
  
  coors = Enrollment.find(:all, :include => [{:contract => :category}, :participant], :conditions => "categories.category_name = 'COOR' and users.privilege = 1")
  coors = coors.group_by{|c| c.participant}
  users = User.student_users
  
  coors.each do |k,v|
    enrollments = v.sort{|x,y| x.enrollment_status<=>y.enrollment_status}
    coor = enrollments[0].contract.facilitator
    
    k.coordinator = coor
    k.user_status ||= User::STATUS_ACTIVE    
    k.save!
  end
  
  # this process kills all facilitator enrollments on contracts
  
  enrollments = Enrollment.find(:all, :include => [:contract, :participant], :conditions => "role = 2")
  enrollments.each do |e|
    raise ArgumentError, "Mismatched facilitator on #{e.contract.name}" if e.participant != e.contract.facilitator
    e.destroy
  end
  
end


task :migrate_credits => :environment do

  ActiveRecord::Base.establish_connection

  enrollments = Enrollment.find(:all)
  enrollments.each do |e|
    next if e.credits.nil?
    
    e.credits.each do |c|
      next if c.empty?
      next if c[:hours] == 0
      credit = Credit.find(c[:id])
      raise ArgumentError, "Credit code #{c[:id]} not found: #{e.participant.last_name_f} / #{e.contract.name}" unless credit

      cred = CreditAssignment.new(:credit => credit, :credit_hours => c[:hours], :district_finalized => false)
      e.credit_assignments << cred
    end      
  end

  contracts = Contract.find(:all)
  contracts.each do |e|
    next if e.credits.nil?
    e.credits.each do |c|
      next if c.empty?
      next if c[:hours] == 0
      credit = Credit.find(c[:id])
      raise ArgumentError, "Credit code #{c[:id]} not found #{contract.name}" unless credit

      cred = CreditAssignment.new(:credit => credit, :credit_hours => c[:hours], :district_finalized => false)
      e.credit_assignments << cred
    end      
  end

end

task :migrate_categories => :environment do

  ActiveRecord::Base.establish_connection

  categories = Category.find(:all)
  categories.each do |c|
    c.public = !['COOR', 'Independent'].include?(c.category_name)
    c.publicly_enrollable = false == ['COOR', 'IEP', 'Seminar', 'Independent'].include?(c.category_name)
    
    if ['Committee','COOR'].include? c.category_name
      c.statusable = Category::STATUSABLE_END
    else
      c.statusable = Category::STATUSABLE_MONTHLY
    end
    
    c.save
    
  end
  unless c = Category.find_by_category_name('Independent')
    c = Category.create(:category_name => 'Independent', :statusable => Category::STATUSABLE_MONTHLY, :public => false, :publicly_enrollable => false)
  end
  
  indys = Contract.find(:all, :conditions => ["name like ?", "%independ%"])
  indys.each do |i|
    i.category = c
    i.save
  end

end



