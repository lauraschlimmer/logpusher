class UploadStats

  MICROS_PER_SECOND = 1000000

  def initialize()
    @rolling_rows_per_second = RollingAggregate.new
    @total_row_count = 0
    @start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def add_upload(num_rows, size_rows = 0)
    @rolling_rows_per_second.add_value(num_rows)
    @total_row_count += num_rows
  end

  def get_rolling_rows_per_second
    aggr = @rolling_rows_per_second.compute_aggregate
    if aggr.interval_us == 0
      return aggr.value
    end
    return Float(aggr.value) / Float(aggr.interval_us)
  end

  def get_total_row_count
    return @total_row_count
  end

  def get_total_runtime
    return Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start
  end
end
