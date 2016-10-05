class LogfilePusher

  KINSERTBATCHSIZE = 1024

  def initialize(logfile, regex, uploader)
    #open file
    regex = Regexp.new(regex)

    records = []
    File.open(logfile).each do |line|
      if !m = line.match(/(?<time>\d{10}) (?<server_name>\w+)/)
        puts  "Dropping logline '#{line}' because it does not match the parsing regex: #{regex}"
        next
      end

      records.push(uploader.buildJSONForLogline(m));

      if records.size() > KINSERTBATCHSIZE
        uploader.upload(records)
        records.clear();
      end
    end

    if records.size() > 0
      uploader.send(records)
    end
  end

end
