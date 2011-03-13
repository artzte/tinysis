require 'fictionalize'

include Fictionalize

namespace :tiny do
  namespace :fake_users do
    
    desc "Fix the foobared attendance records"

    task :add_fake_users => :environment do
      
      coors = []
      
      5.times do |i|
        fn = fictionalized_first_name
        ln = fictionalized_last_name
        u = User.new(:first_name => fn, 
          :last_name => ln, 
          :email => "test+#{ln}-#{fn}@tinysis.org", 
          :password => "fake+teacher+#{i}", 
          :login_status => User::LOGIN_ALLOWED,
          :status => User::STATUS_ACTIVE
        )
        u.login = "#{ln}_#{fn}"
        u.status = User::STATUS_ACTIVE
        u.login_status = User::LOGIN_ALLOWED
        u.password = "fake+teacher+#{i}"
        u.save
        coors << u 
      end
      
      25.times do |i|
        fn = fictionalized_first_name
        ln = fictionalized_last_name
        u = User.new(:first_name => fn, 
          :last_name => ln, 
          :coordinator => coors[i % 5]
        )
        u.login = "#{ln}_#{fn}"
        u.status = User::STATUS_ACTIVE
        u.login_status = User::LOGIN_NONE
        u.save
      end
    end

  end
end
  
