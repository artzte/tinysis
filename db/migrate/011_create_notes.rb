class CreateNotes < ActiveRecord::Migration

  def self.up
    create_table :notes do |t|
      t.column :note, :text
			t.column :creator_id, :integer
			t.column :created_on, :datetime
			t.column :updated_on, :datetime
			t.column :notable_id, :integer
			t.column :notable_type, :string
    end
  end

  def self.down
    drop_table :notes
  end
end
