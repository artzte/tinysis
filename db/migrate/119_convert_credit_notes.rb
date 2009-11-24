class ConvertCreditNotes < ActiveRecord::Migration
  def self.up
    CreditAssignment.find(:all).each do |ca|
      unless ca.note.blank?
        ca.notes << Note.create(:note => ca.note)
      end
    end
  	remove_column :credit_assignments, :note
  end

  def self.down
  	add_column :credit_assignments, :note, :string
  end
end
