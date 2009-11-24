class AddActiveDatesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :date_active, :datetime
    add_column :users, :date_inactive, :datetime

    User.find(:all, :conditions => ["privilege = ?", User::PRIVILEGE_STUDENT]).each do |s|
      s.date_active = Time.mktime(2006,9,1)
      case s.user_status
      when User::STATUS_ACTIVE
        s.date_inactive = nil
      when User::STATUS_INACTIVE
        s.date_inactive = Time.mktime(2007,1,1)
      end
      
      s.coordinator = User.find_by_lastname "cherniak" unless s.coordinator
      
      s.save!
    end
  end
  
  def self.down
    remove_column :users, :date_active
    remove_column :users, :date_inactive
  end
end
