class Turnin < ActiveRecord::Base

  STATUS_TYPES = [
    :missing,
    :incomplete,
    :complete,
    :late,
    :exceptional
  ]

  has_many :notes, :as => :notable, :dependent => :destroy
  belongs_to :enrollment
  belongs_to :assignment, :include => :contract

  validates_inclusion_of :status, :in => STATUS_TYPES

  # Return a hash describing privileges of the specified user
  # on this turnin

  def privileges(user)
    return enrollment.privileges(user)
  end

  def missing?
    self.status == :missing
  end

  def complete?
    [:complete, :exceptional, :late].include? self.status
  end

  def incomplete?
    self.status == :incomplete
  end

  def scode
    attributes['scode'] || self.status.to_s[0,1].upcase
  end

  # This attribute is pulled in select queries. Return TRUE if the attribute
  # indicates "1"
  def has_note?
    attributes['has_note'] ? attributes['has_note'] == '1' : notes.length > 0
  end
end
