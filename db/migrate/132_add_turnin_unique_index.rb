class AddTurninUniqueIndex < ActiveRecord::Migration
  def self.up
    remove_index :turnins, :name => 'index_turnins_on_enrollment_id_and_assignment_id'
    dupies = Turnin.find_by_sql("SELECT turnins.assignment_id, turnins.enrollment_id, turnins.id, counts.count, notes.note FROM turnins
    INNER JOIN (SELECT id, count(id) AS count, assignment_id, enrollment_id FROM turnins GROUP BY CONCAT(enrollment_id, '/', assignment_id)) AS counts ON counts.assignment_id = turnins.assignment_id AND counts.enrollment_id = turnins.enrollment_id
    LEFT OUTER JOIN notes ON notes.notable_id = turnins.id AND notes.notable_type = 'Turnin'
    WHERE counts.count >1
    ORDER BY turnins.assignment_id, turnins.enrollment_id, notes.note DESC, turnins.id")
    
    key = nil
    dupies.each do |dupe|
      cur = [dupe.enrollment_id, dupe.assignment_id]
      keep = key != cur
      key = cur
      dupe.destroy unless keep
    end

    add_index :turnins, [:enrollment_id, :assignment_id], :name => 'index_turnins_on_enrollment_id_and_assignment_id', :unique => true
    
    add_column :turnins, :created_at, :datetime
    add_column :turnins, :updated_at, :datetime
    
  end

  def self.down
  end
end
