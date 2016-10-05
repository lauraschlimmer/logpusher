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
    mtime = nil
    while true
      new_mtime = File.stat(@logfile).mtime.to_i
      if new_mtime != mtime
        uploaded_lines = generate_records(uploaded_lines)
        mtime = new_mtime
      else
        $stderr.puts "Logfile did not change since last push. Waiting..."
      end
      sleep(5)
    end

  end

private
  def generate_records(lines_to_drop = 0) #FIXME better naming
    $stderr.puts "Reading logfile..."

    line_count = 0
    records = []
    idx = 0
    File.open(@logfile).each do |line|
      line_count += 1
      next unless line_count > lines_to_drop

      if !m = line.match(/(?<time>\d{10}) (?<server_name>\w+)/) #FIXME
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
