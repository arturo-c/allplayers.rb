#!/usr/bin/ruby
require 'rubygems'
require 'gdata'
require 'fastercsv'
#require 'php_serialize'
require 'apci_rest'
 
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
#  def serializePHP()
#    php = PHP.serialize(@results)
#    file = File.new(i"#{@fname}.php", 'w')
#    file.puts(php)
#  end
  def saveFile()
    file = File.new("data/#{@fname}.csv", 'w')
    file.puts(@feed.body)
  end
end
 
## load the specified sheet
spreadsheets = {}
spreadsheets['jva'] = 'tGIPL2_D8_JWOLlHURP_1-w'
sheets = {}
sheets[0] = 'jva_users'
sheets[2] = 'jva_leagues'
puts spreadsheets[ARGV[0]]
sheets.each { | tab, fname |
  g = GoogSS.new(spreadsheets[ARGV[0]], fname, tab)
  g.saveFile()
}
#g.serializePHP()
