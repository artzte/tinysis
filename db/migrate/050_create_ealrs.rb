class CreateEalrs < ActiveRecord::Migration

  def self.up
    create_table :ealrs do |t|
			t.column :category, :string
      t.column :seq, :string
			t.column :ealr, :text
			t.column :version, :datetime
    end
  end

  def self.down
    drop_table :ealrs
  end
end
