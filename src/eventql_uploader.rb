require "eventql"

class EventQLUploader

  def self.mandatory_args()
    return [:db, :table, :host, :port]
  end

  def initialize(options)
    #@auth_data = auth_data

    @row = {:database => options[:db], :table => options[:table]}

    @db = EventQL.connect({
      :host => options[:host],
      :port => options[:port],
      :database => options[:db]
    })
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

