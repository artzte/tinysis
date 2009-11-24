class StudentImport < ActiveRecord::Migration
  def self.up
    
    remove_column :users, :birthdate
    
    #     user = User.new
    #     user.privilege = User::PRIVILEGE_STAFF
    #     user.firstname= 'Inactive'
    #     user.lastname = 'Inactive'
    #     user.district_id = nil
    #     user.district_grade = nil
    #     user.login_status = User::LOGIN_NONE
    #     user.user_status = User::STATUS_ACTIVE
    #     user.login = "inactivexyxyxy87767"
    #     user.save!
    # 
    #     user = User.new
    #     user.privilege = User::PRIVILEGE_STAFF
    #     user.firstname= 'Bit'
    # user.lastname = 'Bucket'
    # user.district_id = nil
    # user.district_grade = nil
    # user.login_status = User::LOGIN_NONE
    # user.user_status = User::STATUS_ACTIVE
    # user.login = "bitbucketxxyeer88"
    #     user.save!
  end

  def self.down
    add_column :users, :birthdate, :datetime
  end
end
