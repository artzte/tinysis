class CreateCredits < ActiveRecord::Migration

  def self.up
    create_table :credits do |t|
      t.column :course_name, :string, :null => false
			t.column :course_id, :integer, :default => 0, :null => false
			t.column :course_type, :integer, :default => Credit::TYPE_NONE, :null => false
			t.column :required_hours, :float, :default => 0.0, :null => false
    end
  end

  def self.down
    drop_table :credits
  end
end
