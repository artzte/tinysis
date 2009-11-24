class CreateContractTypes < ActiveRecord::Migration
  def self.up
    create_table :contract_types do |t|
      t.column :name, :string, :null => false
      t.column :public, :boolean, :default => false
      t.column :enrollable, :boolean, :default => false
    end
  end

  def self.down
    drop_table :contract_types
  end
end
