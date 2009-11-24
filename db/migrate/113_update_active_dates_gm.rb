class UpdateActiveDatesGm < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |u|
      u.date_active = Time.gm(2006,9) if u.date_active == Time.mktime(2006,9)
      u.save
    end
  end
  
  def self.down
  end
end
