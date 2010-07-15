#!/usr/bin/ruby
# to run: ruby get_csv.php filename tab_id
require 'rubygems'
require 'gdata'
require 'fastercsv'

class ApciGoogSS
  attr_reader :feed, :results, :diff, :fname
  def initialize(key = nil, fname = 'test_data', tab = 0)
    client = GData::Client::DocList.new
    client.clientlogin('user@gmail.com', '')
    begin
      @feed = client.get("http://spreadsheets.google.com/pub?key=#{key}&single=true&gid=#{tab}&output=csv")
      @results = FasterCSV.parse(@feed.body, {:converters => :all} )
      @fname = fname
    rescue
      puts "You probably forgot to publish the spreadsheet as a csv"
    end
  end
  def results
    @results
  end
end
