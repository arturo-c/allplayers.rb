#!/usr/bin/ruby
# to run: ruby get_csv.php filename tab_id
require 'rubygems'
require 'gdata'
require 'fastercsv'
require 'php_serialize'
require 'rest_client'
require 'yaml'

class GoogSS
  attr_reader :feed, :results, :diff, :fname
  def initialize(key = nil, fname = 'test_data', tab = 0)
    client = GData::Client::DocList.new
    client.clientlogin('allplayersinc@gmail.com', '')
    begin
      @feed = client.get("http://spreadsheets.google.com/pub?key=#{key}&single=true&gid=#{tab}&output=csv")
      @results = FasterCSV.parse(@feed.body, {:converters => :all} )
      @fname = fname
    rescue
      puts "You probably forgot to publish the spreadsheet as a csv"
    end
  end
  def serialize_php()
    php = PHP.serialize(@results)
    file = File.new("#{@fname}.php", 'w')
    file.puts(php)
  end
  def save_file()
    file = File.new("data/#{@fname}.csv", 'w')
    file.puts(@feed.body)
  end
  def print_data()
    #puts @results.inspect
    puts @results.to_yaml
  end
end

## load the specified sheet
spreadsheets = {}
spreadsheets['old'] = 'tSNUn3gxo1KYxh6ifKeDopw'
spreadsheets['nfl'] = 't5iTmNI9ubAq7GgUgv3_64g'
spreadsheets['test'] = 'ts_X_jduwYnWCqFiQRvYHMw'
spreadsheets['fb'] = 'tDXQ3vch0c5lxk5ZMUPriRQ'
spreadsheets['apisd'] = 'ttQCGKmxk90-bOPIiKpIRew'
sheets = {}
sheets[0] = 'users'
sheets[1] = 'teams'
sheets[2] = 'divisions'
sheets[3] = 'leagues'
sheets[4] = 'associations'
sheets[5] = 'games'
sheets[6] = 'events'
puts spreadsheets[ARGV[0]]
sheets.each { | tab, fname |
  g = GoogSS.new(spreadsheets[ARGV[0]], fname, tab)
  #g.serialize_php()
}
