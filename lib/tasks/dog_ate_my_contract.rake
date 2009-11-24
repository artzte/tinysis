namespace :dog_ate do
  
  desc 'Extract contract data for a given range of contract IDs'

  task :extract_contracts => :environment do
  
    cids = ENV["cids"]
  
    raise ArgumentError, "Specify cids=\"comma_separated_contract_id_list\"" if cids.nil?

    ActiveRecord::Base.establish_connection
  
    contracts = Contract.find(:all, :conditions => "id in (#{cids})")
    enrollments = Enrollment.find(:all, :conditions => "contract_id in (#{cids})")
    eids = enrollments.collect{|e| e.id}.join(',')
    sql  = "SELECT * FROM %s WHERE %s"
    {
      "contracts" => "id in (#{cids})", 
      "enrollments" => "contract_id in (#{cids})", 
      "statuses" => "statusable_id in (#{eids}) and statusable_type = 'Enrollment'", 
      "absences" => "enrollment_id in (#{eids})", 
      "notes" => "notable_id in (#{eids}) and notable_type = 'Enrollment'"
    }.each do |k,v|
      i = "000"
      data = ActiveRecord::Base.connection.select_all(sql % [k,v])  
      File.open("#{RAILS_ROOT}/test/fixtures/contracts/#{k}.yml", 'w') do |file|
        file.write data.inject({}) { |hash, record|
          hash["#{k}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end

  end


  task :restore_contracts => :environment do
  
    fixtures = {}
    Dir.entries("#{RAILS_ROOT}/test/fixtures/contracts").each do |fixture_file|

      next unless fixture_file =~ /^(\w+)\.yml$/
    
      fixtures[$1] = YAML::load(File.open("#{RAILS_ROOT}/test/fixtures/contracts/#{fixture_file}"))

    end
  
    fixtures["contracts"].each do |k,v|
      c = Contract.new(v)
      c.id = v['id'].to_i
      c.save
    end
  
    fixtures["enrollments"].each do |k,v|
      e = Enrollment.new(v)
      e.id = v['id'].to_i
      e.save
    end
  
    fixtures["statuses"].each do |k,v|
      s = Status.new(v)
      s.id = v['id'].to_i
      s.save
    end
  
    fixtures["absences"].each do |k,v|
      a = Absence.new(v)
      a.id = v['id'].to_i
      a.save
    end
  
    fixtures["notes"].each do |k,v|
      n = Note.new(v)
      n.id = v['id'].to_i
      n.save
    end
  
  end


  task :print_coor_credits => :environment do
  
    coor = ENV["COOR"]
  
    raise ArgumentError, "Specify COOR=\"coordinator_last_name\"" if coor.nil?

    ActiveRecord::Base.establish_connection
  
    u = User.find(:first, :conditions => ["last_name = ? and privilege >= ?", coor, User::PRIVILEGE_STAFF])
  
    raise ArgumentError, "Could not find coordinator #{coor}" unless u
  
    coors = u.coordinatees
  
    File.open("#{RAILS_ROOT}/#{coor}.txt", 'w') do |file|
    
      file.write "Student Name\tContract Name\tCredit Name\tHours\tEnrollment Finalized\tCredit Finalized\tNotes\n"
      coors.each do |c|
    
        c.credit_assignments.each do |ca|
          file.write "#{c.last_name_first}\t#{ca.contract_name}\t#{ca.credit.course_name}\t#{ca.credit_hours}\t#{ca.enrollment_finalized_on}\t#{ca.district_finalize_approved_on}\n"
        end
      end
    end
  
  end

  desc "User created a duplicate contract, has decided to move his enrollments over into the new contract"
  task :move_enrollments_to_different_contract => :environment do
    raise ArgumentError, "Specify DB ID of source and destination contract SOURCE=<id> DEST=<id>" unless ENV['SOURCE'] && ENV['DEST']
    
    dest = Contract.find ENV['DEST']
    source = Contract.find ENV['SOURCE']
    
    source_assignments = source.assignments.find(:all, :order => 'due_date asc')
    dest_assignments =   dest.assignments.find(:all, :order => 'due_date asc') 

    Enrollment.update_all(["contract_id = ?", dest.id], ["contract_id = ?", source.id])
    source_assignments.each_with_index do |a,i|
      Turnin.update_all(["assignment_id = ?", dest_assignments[i].id], ["assignment_id = ?", a.id])
    end
  end
  
end