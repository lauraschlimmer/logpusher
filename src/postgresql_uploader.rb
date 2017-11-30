require "pg"

class PostgreSQLUploader

  def self.mandatory_args()
    return [:host, :port, :db, :table]
  end

  def initialize(options)
    @table = options[:table]
    @db_opts = {
      :dbname => options[:db],
      :host => options[:host],
      :port => options[:port],
      :user => options[:user]
    }
  end

  def insert(lines)
    conn = PG::Connection.new(@db_opts)

    rows = []
    lines.each do |line|
      values = []
      line.names.each do |col|
        values.push(line[col])
      end

      query = "INSERT INTO #{@table} " \
              "  (#{line.names.join(", ")}) " \
              "VALUES " \
              "  (#{Array.new(values.size) {|i| "$#{i+1}"}.join(",")});"

      begin
        result = conn.exec_params(query, values)
      rescue Exception => e
        puts e.inspect
        # FIXME try again
      end
    end

    conn.finish unless conn.finished?
  end

end
