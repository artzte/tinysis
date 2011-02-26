class AddTimestampsToCreditAssignments < ActiveRecord::Migration
  def self.up
    add_timestamps(:credit_assignments)
  end

  def self.down
    raise RuntimeError
  end
end
