class LogfilePusher

  INSERT_BATCH_SIZE = 2 #FIXME
  NUM_THREADS = 3

  def initialize(logfile, regex, uploader, quiet=false)
    @logfile = logfile
    @regex = Regexp.new(regex)
    @uploader = uploader
    @quiet = quiet
    @stats = UploadStats.new
    @queue = Array.new
    @complete = false
    @mutex = Mutex.new
    @cv = ConditionVariable.new

    if !File.file?(@logfile)
      raise "the file doesn't exist: #{@logfile}"
    end
  end

public

  def run
    offset = 0
    cur_inode = nil
    cur_size = nil

    #while true FIXME
      # if the inode number of the file changes (e.g. the file has been
      # logrotated), start reading the file at the beginning
      if (inode = File.stat(@logfile).ino) != cur_inode
        cur_size = File.size(@logfile)
        cur_inode = inode
        offset = run_(0)

      # if the file size is smaller, start reading at the beginning
      elsif (size = File.size(@logfile)) < cur_size
        cur_size = size
        offset = run_(0)

      # if the file is bigger, start reading at the offset
      elsif size > cur_size
        cur_size = size
        offset = run_(offset)

      else
        print_stats("wait")
      end

      sleep(5)
    #end

  end

  def stop
    #FIXME close file?
    print_stats("stop")
  end

private

  def run_(offset = 0)
    # start threads
    threads = Array.new(NUM_THREADS) do
      Thread.new do
        run_thread()
      end
    end

    # read and enqueue lines in batches
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

      if batch.size >= INSERT_BATCH_SIZE
        enqueue_batch(batch)
        batch.clear()
      end

      batch.push(m)

      print_stats("upload")
    end

    if batch.size > 0
      enqueue_batch(batch)
    end

    # send upload complete signal
    @mutex.synchronize {
      @complete = true
      @cv.signal
    }

    # join threads
    threads.each { |th| th.join }

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

        if @complete
          return nil
        else
          @cv.wait(@mutex)
        end
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
      print_stats("upload")
    end
  end

  def print_stats(state)
    return if @quiet

      case state
      when "upload"
        @mutex.synchronize {
          $stderr.print "Uploading... rate=#{@stats.get_rolling_rows_per_second}lines/s\r"
        }

      when "wait"
        $stderr.print "Waiting... the file hasn't changed since the last upload\r"

      when "stop"
        $stderr.print "Uploaded #{@logfile}... " +
            "total=#{@stats.get_total_row_count}lines, " +
            "runtime=#{@stats.get_total_runtime.round(2)}s\n"

      end

      $stderr.flush
  end

end
