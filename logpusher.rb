#!/usr/bin/env ruby

require 'optparse'

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

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "help") do
    puts opts
    exit
  end
end.parse!

mandatory_args = [:file, :regex]
missing = mandatory_args.select{ |param| options[param].nil? }
unless missing.empty?
  puts "missing arguments: #{missing.join(', ')}. Run logpusher.rb --help for help"
  exit
end

p options
p ARGV
