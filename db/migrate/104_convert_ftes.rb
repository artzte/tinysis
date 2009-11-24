class ConvertFtes < ActiveRecord::Migration
  def self.up
    add_column :statuses, :fte_hours, :integer, :default => 25
    
    Status.find(:all).each do |s|
      s.fte_hours = s.fte * 25
      s.save
    end
    
    remove_column :statuses, :fte
  end

  def self.down
    
    add_column :statuses, :fte, :float, :default => 1.0
    Status.find(:all).each do |s|
      s.fte = s.fte_hours / 25
      s.save
    end
    remove_column :statuses, :fte_hours
  end
  
end
