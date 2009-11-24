class CreateContractEalrs < ActiveRecord::Migration

  def self.up
    create_table :contract_ealrs, :id => false do |t|
      t.column :contract_id, :integer
			t.column :ealr_id, :integer
    end
  end

  def self.down
    drop_table :contract_ealrs
  end
end
