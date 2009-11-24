class CreateTurnins < ActiveRecord::Migration

  def self.up
    create_table :turnins do |t|
			t.column :enrollment_id, :integer, :null => false
			t.column :assignment_id, :integer, :null => false
			t.column :complete, :boolean, :null => false, :default => true
    end
  end

  def self.down
    drop_table :turnins
  end
end
