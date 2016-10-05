#!/usr/bin/env ruby

require 'optparse'
require 'uri'
require 'net/http'

require "./src/util.rb"
require "./src/logfile_pusher.rb"
require "./src/logfile_uploader.rb"
require "./src/eventql_uploader.rb"

# parse arguments
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: logpusher.rb [options]"

  opts.on("-f", "--file filename", "Set the logfile to import") do |f|
    options[:file] = f
  end

  opts.on("-r", "--regex regex", "The Regex of the logline") do |r|
    options[:regex] = r
  end

  opts.on("-t", "--table table", "Set the table name") do |t|
    options[:table] = t
  end

  opts.on("-host", "--host hostname", "Set the hostname") do |h|
    options[:host] = h
  end

  opts.on("-p", "--port port", "Set the port") do |p|
    options[:port] = p
  end

  opts.on("-u", "--user username", "Set the username") do |u|
    options[:user] = u
  end

  opts.on("", "--password password", "Set the password") do |u|
    options[:user] = u
  end

  opts.on("-d", "--database db", "Set the database") do |d|
    options[:database] = d
  end

  opts.on("", "--auth_token auth_token", "Set the auth token") do |a|
    options[:auth_token] = a
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("", "--help", "help") do
    puts opts
    exit
  end
end.parse!

mandatory_args = [:file, :regex, :table, :host, :port, :database]
missing = mandatory_args.select{ |param| options[param].nil? }
unless missing.empty?
  puts "missing arguments: #{missing.join(', ')}. Run logpusher.rb --help for help"
  exit
end

auth_data = {};
if options[:user]
  auth_data[:user] = options[:user]
end

if options[:password]
  auth_data[:password] = options[:password]
end

if options[:auth_token]
  auth_data[:auth_token] = options[:auth_token]
end

begin
  uploader = EventQLUploader.new(
      options[:table],
      options[:host],
      options[:port],
      options[:database],
      auth_data)

  pusher = LogfilePusher.new(options[:file], options[:regex], uploader)
  pusher.run

rescue
  $stderr.puts "ERROR: #{$!} \n"
  exit(1)
end

