class LogfilePusher

  INSERT_BATCH_SIZE = 48 #FIXME = 1024

  def initialize(logfile, regex, uploader)
    @logfile = logfile
    @regex = Regexp.new(regex)
    @uploader = uploader

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
        offset = upload_file(0)
        cur_size = File.size(@logfile)
        cur_inode = inode

      else
        size = File.size(@logfile)

        # if the file size is smaller, start reading at the beginning
        if size < cur_size
          cur_size = size
          offset = upload_file(0)

        # if the file is bigger, start reading at the offset
        elsif size > cur_size
          cur_size = size
          offset = upload_file(offset)

        else
          $stderr.puts "[WAITING] Logfile did not change since last push."
        end
      end

      sleep(5)
    end

  end

private

  # read the @logfile starting at position offset and push the loglines
  #
  # return the last position of the file
  def upload_file(offset = 0)
    $stderr.puts "Reading logfile..."

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
        lines.push(@uploader.buildJSONForLogline(m))
      end

      line.clear()
    end

    @uploader.send(lines)

    return line.split("")
  end

end
