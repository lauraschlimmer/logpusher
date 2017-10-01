class LogfilePusher

  INSERT_BATCH_SIZE = 1024

  def initialize(logfile, regex, uploader, quiet=false)
    @logfile = logfile
    @regex = Regexp.new(regex)
    @uploader = uploader
    @quiet = quiet
    @stats = UploadStats.new

    if !File.file?(@logfile)
      raise "the file doesn't exist: #{@logfile}"
    end
  end

public

  def run
    offset = 0
    cur_inode = nil
    cur_size = nil

    while true
      # if the inode number of the file changes (e.g. the file has been
      # logrotated), start reading the file at the beginning
      if (inode = File.stat(@logfile).ino) != cur_inode
        cur_size = File.size(@logfile)
        cur_inode = inode
        offset = upload_file(0)

      # if the file size is smaller, start reading at the beginning
      elsif (size = File.size(@logfile)) < cur_size
        cur_size = size
        offset = upload_file(0)

      # if the file is bigger, start reading at the offset
      elsif size > cur_size
        cur_size = size
        offset = upload_file(offset)

      else
        print_stats("wait")
      end

      sleep(5)
    end

  end

  def stop
    #FIXME close file?
    print_stats("stop")
  end

private

  # read the @logfile starting at position offset and push the loglines
  #
  # return the last position of the file
  def upload_file(offset = 0)
    buffer = []
    idx = 0
    File.open(@logfile) do |file|
      while (chunk = file.read(1))
        if (idx += 1) < offset
          next
        end
        buffer.push(chunk)

        if buffer.size > INSERT_BATCH_SIZE
          buffer = processBuffer(buffer)
        end
      end
    end

    if buffer.size > 0
      processBuffer(buffer)
    end

    return idx
  end

  # build up lines from the buffer, a line ends with \n, and push these lines
  #
  # if the last line is not complete, that is the buffer doesn't end with a line
  # ending, an array with the remaining characters will be returned.
  # Otherwise an empty array will be returned.
  def processBuffer(buffer)
    lines = []
    line = ""
    buffer.each do |c|
      if c != "\n"
        line += c
        next
      end

      if !m = line.match(@regex)
        $stderr.puts  "Dropping logline '#{line}' because it does not match the parsing regex: #{@regex}"
      else
        lines.push(m)
      end

      line.clear()
    end

    @uploader.insert(lines)

    @stats.add_upload(lines.size)
    print_stats("upload")

    return line.split("")
  end

  def print_stats(state)
    return if @quiet

    $stderr.flush
    case state
    when "upload"
      $stderr.print "Uploading... rate: #{@stats.get_rolling_rows_per_second} lines per second\r"

    when "wait"
      $stderr.print "Waiting... the file hasn't changed since the last upload\r"

    when "stop"
      $stderr.print "Uploaded #{@logfile}..." +
          "total: #{@stats.get_total_row_count} lines, " +
          "runtime: #{@stats.get_total_runtime.round(2)}s\n"

    end
  end

end
