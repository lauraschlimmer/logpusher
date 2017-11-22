class LogfilePusher

  DEFAULT_BATCH_SIZE = 2 #FIXME
  DEFAULT_NUM_THREADS = 3

  def initialize(uploader, opts)
    # mandatory
    @logfile = opts[:file]
    if !File.file?(@logfile)
      raise "the file doesn't exist: #{@logfile}"
    end

    @regex = Regexp.new(opts[:regex])

    # optional
    @quiet = opts.has_key?(:quiet) ? opts[:quiet] : false
    @num_threads = opts.has_key?(:connections) ?
        opts[:connections] :
        DEFAULT_NUM_THREADS
    @batch_size = opts.has_key?(:batch_size) ?
        opts[:batch_size] :
        DEFAULT_BATCH_SIZE

    @uploader = uploader
    @stats = UploadStats.new
    @queue = Array.new
    @mutex = Mutex.new
    @cv = ConditionVariable.new
    @threads = Array.new
  end

public

  def run
    offset = 0
    cur_inode = nil
    cur_size = nil

    # start threads
    @threads = Array.new(@num_threads) do
      Thread.new do
        run_thread()
      end
    end

    while true
      # if the inode number of the file changes (e.g. the file has been
      # logrotated), start reading the file at the beginning
      if (inode = File.stat(@logfile).ino) != cur_inode
        cur_size = File.size(@logfile)
        cur_inode = inode
        offset = process_file(0)

      # if the file size is smaller, start reading at the beginning
      elsif (size = File.size(@logfile)) < cur_size
        cur_size = size
        offset = process_file(0)

      # if the file is bigger, start reading at the offset
      elsif size > cur_size
        cur_size = size
        offset = process_file(offset)

      else
        print_stats(:Wait)
      end

      sleep(2)
    end

    @threads.each do |th|
      if th
        th.join()
      end
    end
  end

  def stop
    #FIXME close file?
    # join threads
    puts @threads.inspect
    print_stats(:Stop)
  end

private

  # read and enqueue lines in batches
  def process_file(offset = 0)
    batch = Array.new
    idx = 0
    IO.readlines(@logfile).each do |line|
      if (idx += 1) <= offset
        next
      end

      m = line.match(@regex)
      if !m
        $stderr.puts  "Dropping logline '#{line}' because it does not match the parsing regex: #{@regex}"
        next
      end

      if batch.size >= @batch_size
        enqueue_batch(batch)
        batch.clear()
      end

      batch.push(m)
    end

    if batch.size > 0
      enqueue_batch(batch)
    end

    return idx
  end

  def enqueue_batch(batch)
    @mutex.synchronize {
      @queue.push(batch)
      @cv.signal
    }
  end

  def pop_batch()
    @mutex.synchronize {
      loop do
        if @queue.size != 0
          break;
        end

        @cv.wait(@mutex)
      end

      batch = @queue.shift
      @cv.signal
      return batch
    }
  end

  def run_thread()
    while (batch = pop_batch)
      @uploader.insert(batch)
      @stats.add_upload(batch.size)
      print_stats(:Upload)
    end
  end

  def print_stats(state)
    return if @quiet

      case state
      when :Upload
        @mutex.synchronize {
          $stderr.print "Uploading... rate=#{@stats.get_rolling_rows_per_second}lines/s\r"
        }

      when :Wait
        $stderr.print "Waiting... the file hasn't changed since the last upload\r"

      when :Stop
        $stderr.print "Uploaded #{@logfile}... " +
            "total=#{@stats.get_total_row_count}lines, " +
            "runtime=#{@stats.get_total_runtime.round(2)}s\n"

      end

      $stderr.flush
  end

end
