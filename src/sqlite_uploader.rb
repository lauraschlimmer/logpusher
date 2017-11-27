require "sqlite3"

class SQLiteUploader

  def self.mandatory_args()
    return [:table, :db]
  end

  def initialize(options)

    @table = options[:table]
    @db = SQLite3::Database.new(options[:db])
  end

  def insert(lines)

    rows = []
    lines.each do |line|
      values = []
      line.names.each do |col|
        values.push(line[col])
      end

      query = "INSERT INTO #{@table} " \
              "  (#{line.names.join(", ")}) " \
              "VALUES " \
              "  (#{Array.new(values.size, "?").join(",")});"

      @db.execute(query, values)
    end
  end
end

