require 'optparse'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: release.rb -v VERSION"

  opts.on("-v", "--version", "Specify version") do |v|
    options[:version] = v
  end
end.parse!

unless options[:version]
  puts "Error: version must be specified"
  exit 0
end

version = options[:version]


