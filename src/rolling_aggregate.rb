class RollingAggregate

  BUCKETS_CAPACITY = 10
  BUCKET_INTERVAL_US = 1000000 / 100

  Struct.new("Bucket", :time, :value, :count)
  Struct.new("Aggregate", :value, :count, :interval_us)

  def initialize
    @buckets_idx = 0
    @buckets_size = 0
    @buckets = []
    (0...BUCKETS_CAPACITY).each do
      @buckets.push(Struct::Bucket.new(0, 0, 0))
    end
  end

public

  def add_value(value)
    cur_time = (
        Process.clock_gettime(Process::CLOCK_MONOTONIC) / BUCKET_INTERVAL_US) *
        BUCKET_INTERVAL_US

    if @buckets_size == 0 || @buckets[@buckets_idx].time != cur_time
      @buckets_idx = (@buckets_idx + 1) % BUCKETS_CAPACITY
      if @buckets_size < BUCKETS_CAPACITY
        @buckets_size += 1
      end

      @buckets[@buckets_idx].time = cur_time
      @buckets[@buckets_idx].value = 0
      @buckets[@buckets_idx].count = 0
    end

    raise "buckets size > buckets_idx" unless @buckets_idx < @buckets.size()
    @buckets[@buckets_idx].value += value
    @buckets[@buckets_idx].count += 1
  end

  def compute_aggregate()
    aggregate = Struct::Aggregate.new(0, 0, 0)
    time_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    time_range = BUCKET_INTERVAL_US * BUCKETS_CAPACITY
    time_begin = time_now
    if time_now >= time_range
      time_begin -= time_range
    else
      time_begin = 0
    end

    idx = (@buckets_idx + (BUCKETS_CAPACITY - @buckets_size) + 1) %
        BUCKETS_CAPACITY

    aggregate.interval_us = @buckets_size == 0 || time_now < @buckets[idx].time ?
        0 :
        time_now.round(4) - @buckets[idx].time.round(4)

    (0...@buckets_size).each do
      if @buckets[idx].time >= time_begin
        aggregate.value += @buckets[idx].value
        aggregate.count += @buckets[idx].count
      end

      idx = (idx + 1) % BUCKETS_CAPACITY
    end

    return aggregate
  end
end
