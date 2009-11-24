class UpdateTermsContract < ActiveRecord::Migration
  def self.up
    # serialized array
    add_column :terms, :months, :text
    add_column :contracts, :contract_type, :integer
  end

  def self.down
    remove_column :terms, :months
    remove_column :contracts, :contract_type
  end
end
