class Category < ActiveRecord::Base
  include StripTagsValidator

  has_many :contracts

  STATUSABLE_NONE = 0
  STATUSABLE_MONTHLY = 1
  STATUSABLE_END = 2

  STATUSABLE_NAMES = {
    STATUSABLE_NONE => "None",
    STATUSABLE_MONTHLY => "Monthly",
    STATUSABLE_END => "End of term"
  }

  def self.statusable
    Category.find(:all, :conditions => "statusable != #{STATUSABLE_NONE}", :order => 'name')
  end

  def self.all
    Category.all_query
  end

  def self.all_public
    Category.all_query(:public => true)
  end

  def self.all_private
    Category.all_query(:public=> false)
  end

protected
  def self.all_query(options = {})
    q = []
    q << "SELECT categories.*, COALESCE(contracts.count,0) AS contract_count FROM categories"
    q << "LEFT OUTER JOIN (SELECT category_id, COUNT(id) AS count FROM contracts GROUP BY category_id) AS contracts ON categories.id = contracts.category_id"
    q << "WHERE categories.public = true" if options[:public]
    q << "WHERE categories.public = false" if options[:public] == false
    q << "ORDER BY categories.name"

    Category.find_by_sql(q.join(' '))
  end

end
