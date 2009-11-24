class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.column :setting_name, :string, :null => false
			t.column :setting_value, :text, :null => false
    end
  end

  def self.down
    drop_table :settings
  end
end
