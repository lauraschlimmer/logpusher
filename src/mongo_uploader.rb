require "mongo"

class MongoUploader

  def self.mandatory_args()
    return [:host, :port, :table, :db]
  end

  def initialize(options)
    Mongo::Logger.logger.level = Logger::FATAL

    mongo_address = "#{options[:host]}:#{options[:port]}"
    client = Mongo::Client.new([mongo_address], :database => options[:db])

    @collection = client[options[:table]]
  end

  def insert(lines)
    docs = []

    lines.each do |line|
      doc = {}
      line.names.each do |col|
        doc[col] = line[col]
      end
      docs.push(doc)
    end

    result = @collection.insert_many(docs)
    raise unless result.inserted_count == docs.length
  end
end


