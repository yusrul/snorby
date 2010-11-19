class Cache

  include DataMapper::Resource

  property :id, Serial

  property :sid, Integer

  property :cid, Integer

  property :ran_at, DateTime

  property :event_count, Integer, :default => 0

  property :tcp_count, Integer, :default => 0

  property :udp_count, Integer, :default => 0

  property :icmp_count, Integer, :default => 0

  property :classification_metrics, Object

  property :severity_metrics, Object

  property :signature_metrics, Object

  # Define created_at and updated_at timestamps
  timestamps :at

  belongs_to :sensor, :parent_key => :sid, :child_key => :sid

  has 1, :event, :parent_key => [ :sid, :cid ], :child_key => [ :sid, :cid ]

  def self.last_month
    all(:ran_at.gte => 2.month.ago.beginning_of_month, :ran_at.lte => 1.month.ago.end_of_month)
  end

  def self.this_month
    all(:ran_at.gte => Time.now.beginning_of_month, :ran_at.lte => Time.now.end_of_month)
  end

  def self.last_week
    all(:ran_at.gte => 2.week.ago.beginning_of_week, :ran_at.lte => 1.week.ago.end_of_week)
  end

  def self.this_week
    all(:ran_at.gte => Time.now.beginning_of_week, :ran_at.lte => Time.now.end_of_week)
  end

  def self.yesterday
    all(:ran_at.gte => 1.day.ago.beginning_of_day, :ran_at.lte => 1.day.ago.end_of_day)
  end

  def self.today
    all(:ran_at.gte => Time.now.beginning_of_day, :ran_at.lte => Time.now.end_of_day)
  end

  def self.severity_count(type)
    @cache = self.map(&:severity_metrics)
    count = []
    case type.to_sym
    when :high
      @cache.each { |x| count << (x.kind_of?(Hash) ? (x.has_key?(1) ? x[1] : 0) : 0) }
    when :medium
      @cache.each { |x| count << (x.kind_of?(Hash) ? (x.has_key?(2) ? x[2] : 0) : 0) }
    when :low
      @cache.each { |x| count <<( x.kind_of?(Hash) ? (x.has_key?(3) ? x[3] : 0) : 0) }
    end
    count
  end

  def self.sensor_metrics
    @metrics = []

    Sensor.all(:limit => 5, :order => [:events_count.desc]).each do |sensor|
      count = Array.new(24) { 0 }
      blah = self.all(:sid => sensor.sid).group_by { |x| x.ran_at.hour }

      blah.each do |hour, data|
        count[hour] = data.map(&:event_count).sum
      end

      @metrics << { :name => sensor.name, :data => count }
    end
    
    @metrics
  end

  def self.classification_metrics
    @cache = self.map(&:classification_metrics)
    @classifications = []
    
    Classification.each do |classification|
      count = 0
      @cache.each do |cache|
        next unless cache
        count += cache[classification.id]
      end
      @classifications << [classification.name, count]
    end
    @classifications
  end

end
