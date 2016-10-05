class EventQLUploader < LogfileUploader

  API_URL = "/api/v1/tables/insert"

  def initialize(table_name, host, port, database, auth_data)
    @url = URI("#{host}:#{port}#{API_URL}")
    @host = host
    @port = port
    @auth_data = auth_data
    @json_begin =
        "{\"database\": \"#{database}\", \"table\": \"#{table_name}\", \"data\": "
  end

  def buildJSONForLogline(logline)
    idx = 0
    json = "{"

    logline.names.each do |key|
      value = logline[key]

      json += "," unless idx == 0
      json += "\"#{key}\": "
      json += value.numeric? ? value : "\"#{value}\""

      idx += 1
    end

    json += "}"
    json
  end

  def send(records)
    idx = 0
    json = "["
    records.each do |r|
      if idx > 0
        json += ","
      end

      json += @json_begin + r + "}"
      idx += 1
    end
    json += "]"
    puts json

    begin
      res = nil
      Net::HTTP.start(@host, @port) do |http|
        req = Net::HTTP::Post.new(API_URL)
        req.body = json

        res = http.request(req)
      end

      if res.code.to_i != 201
        raise "http error: #{res.code} - #{res.body}"
      end

    rescue TimeoutError => e
      $stderr.puts("Timeout error...", e.inspect)
    end

    $stderr.puts("Inserted records...")
  end

end

