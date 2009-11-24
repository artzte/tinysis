class AddMonthEnrollmentIndex < ActiveRecord::Migration
  def self.up
    dupies = Status.find_by_sql("
      SELECT id, statuses.month, statuses.statusable_id, statuses.statusable_type, counts.count FROM statuses 
      INNER JOIN (select count(id) as count, month, statusable_type, statusable_id FROM statuses GROUP BY month, statusable_type, statusable_id) AS counts 
      ON statuses.month = counts.month AND statuses.statusable_id = counts.statusable_id AND statuses.statusable_type = counts.statusable_type AND counts.count > 1 
      ORDER BY id ASC")
      
    key = nil
    dupies.each do |dupe|
      cur = [dupe.month, dupe.statusable_id, dupe.statusable_type]
      keep = key != cur
      key = cur
      puts dupe.id if keep
      dupe.destroy unless keep
    end

    add_index :statuses, [:statusable_id, :statusable_type, :month], :name => 'index_statuses_on_statusable_and_month', :unique => true
  end

  def self.down
  end
end
