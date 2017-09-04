require "eventql"

class EventQLUploader

  def initialize(table_name, host, port, database, auth_data)
    @auth_data = auth_data
    @row = {:database => database, :table => table_name}

    @db = EventQL.connect({:host => host, :port => port, :database => database})
  end

  def insert(lines)
    data = []
    lines.each do |line|
      row = @row.clone

      d = {}
      line.names.each do |key|
        value = line[key]
        d[key] = value.numeric? ? line[key].to_i : line[key]
      end

      row[:data] = d
      data.push(row)
    end

    @db.insert!(data)
  end
end

