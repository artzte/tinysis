class RemoveCommunityGrade < ActiveRecord::Migration
  def self.up
    remove_column :users, :community_grade
  end

  def self.down
  end
end
