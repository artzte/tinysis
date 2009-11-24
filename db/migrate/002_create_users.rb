class CreateUsers < ActiveRecord::Migration

  def self.up
    create_table :users do |t|
			t.column :login, :string
			t.column :login_status, :integer, :default => User::LOGIN_NONE
			t.column :firstname, :string, :null => false
			t.column :lastname, :string, :null => false
			t.column :nickname, :string
			t.column :email, :string, :default => nil
			t.column :privilege, :integer, :default => User::PRIVILEGE_NONE, :null => false
			t.column :user_status, :integer, :default => User::STATUS_BOGUS, :null => false
			t.column :district_id, :string
			t.column :district_grade, :integer
			t.column :community_grade, :integer
			t.column :birthdate, :datetime
			t.column :password_hash, :string
			t.column :password_salt, :string
    end
		
	end

  def self.down
    drop_table :users
  end
end
