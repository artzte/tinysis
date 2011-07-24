class ClassPeriod
  
  attr_accessor :period, :start, :end, :weekdays
  WEEKDAYS = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ] 
  
  def initialize(start_time = nil, end_time = nil, period = nil)
    
    self.start = start_time
    self.end = end_time
    self.period = period
    
  end
  
	# creates a text representation of the period

  def timeslot_string

		ret = ""
		self.weekdays.each{|w| ret << WEEKDAYS[w].slice(0,3) << "/" }
		ret.chomp! "/"
		ret << " #{period_string}"
    
  end
  
  def timeslot_hash
    
    ret = { :weekdays => self.weekdays.to_s, :start => self.start, :end => self.end }
    
  end
  
  def self.from_timeslot_hash(p)
    
    period = self.new(p[:start], p[:end])
    period.weekdays = p[:weekdays].split("").collect{|i| i.to_i}
	  
    period
    
  end
  
  def self.timeslot_strings(ts_hash)
    return ["Unspecified"] if ts_hash.empty?
    strings = []
    ts_hash.each do |t|
      next if t.empty?
      per = ClassPeriod.from_timeslot_hash(t)
      strings << per.timeslot_string
    end
    return ["Unspecified"] if strings.empty?
    strings
  end
  
  # creates a text representation of the timeslot
  
  def period_string
    
    "#{self.start}-#{self.end}"
  
  end
  
  def self.from_period_string(s)
    
    s =~ /^(\d+:\d+)-(\d+:\d+)$/
    self.new($1,$2)
    
  end
  
end
