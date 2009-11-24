class CreditTransmittedDate < ActiveRecord::Migration
  def self.up
    add_column :credit_assignments, :district_transmitted_on, :datetime
    add_column :credit_assignments, :override_hours, :float
    add_column :credit_assignments, :override_by, :string
    remove_column :credit_transmittal_batches, :transmitted
  end

  def self.down
  	remove_column :credit_assignments, :district_transmitted_on
  	remove_column :credit_assignments, :override_hours
  	remove_column :credit_assignments, :override_by
    add_column :credit_transmittal_batches, :transmitted, :boolean
  end
end
