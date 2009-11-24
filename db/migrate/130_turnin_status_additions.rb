class TurninStatusAdditions < ActiveRecord::Migration
  def self.up
    change_column :turnins, :status, :enum, :limit => Turnin::STATUS_TYPES, :default => Turnin::STATUS_TYPES.first, :null => false
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
