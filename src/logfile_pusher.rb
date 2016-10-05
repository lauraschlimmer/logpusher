class LogfilePusher

  INSERT_BATCH_SIZE = 1024

  def initialize(logfile, regex, uploader)
    @logfile = logfile
    @regex = Regexp.new(regex)
    @uploader = uploader
  end

public
  def run
    uploaded_lines = 0
    cur_mtime = nil
    cur_inode = nil

    while true
      #check if file has been logrotated
      if (inode = File.stat(@logfile).ino) != cur_inode
        uploaded_lines = upload_file(0)
        cur_inode = inode
        cur_mtime = File.stat(@logfile).mtime.to_i

      #check if file has been modified since last upload
      elsif (mtime = File.stat(@logfile).mtime.to_i) != cur_mtime
        uploaded_lines = upload_file(uploaded_lines)
        cur_mtime = mtime

      else
        $stderr.puts "Logfile did not change since last push. Waiting..."
      end

      sleep(5)
    end

  end

private
  def upload_file(lines_to_drop = 0)
    $stderr.puts "Reading logfile..."

    records = []
    line_count = 0
    File.open(@logfile).each_with_index do |line, index|
      if index == 0

      end

      line_count = index
      next unless index > lines_to_drop
      if !m = line.match(@regex)
        $stderr.puts  "Dropping logline '#{line}' because it does not match the parsing regex: #{@regex}"
        next
      end

      records.push(@uploader.buildJSONForLogline(m));

      if records.size() > INSERT_BATCH_SIZE
        @uploader.send(records)
        records.clear();
      end

    end

    if records.size() > 0
      @uploader.send(records)
    end

    return line_count
  end
end
