#!/usr/bin/ruby
require 'rubygems'
require 'apci_gdoc'
require 'apci_rest'
require 'php_serialize'

# Little utility to convert array to Hash with defined keys.
class Array
  def to_hash(other)
    Hash[ *(0...other.size()).inject([]) { |arr, ix| arr.push(other[ix], self[ix]) } ]
  end
end

module ImportActions
  def import_user(item, columns)
    hash = item.to_hash(columns)
    #log stuff!!
  end
end

## load the specified sheet
spreadsheets = {}
spreadsheets['import'] = '0AnrE8fZqLiAXdEFYQ3hpelk2VUFPTWRvTWRPSFQzM3c'
sheets = {}
sheets[0] = 'Users'
sheets[1] = 'Groups'
sheets[2] = 'Events'
sheets[3] = 'Users in Groups'
puts spreadsheets[ARGV[0]]
sheets.each { | tab, fname |
  g = ApciGoogSS.new(spreadsheets[ARGV[0]], fname, tab)
  apci_session = ApcirClient.new(nil, 'vbox.allplayers.com')
  apci_session.login('user', '')
  apci_session.extend ImportActions
  # Take the first row and use it to define columns.
  column_defs = g.results.shift
  # Detect sheet type / Sanity Check
  if (2 <= (column_defs & ['First Name', 'Last Name']).length)
    puts "User\n"
    g.results.each {|item| apci_session.import_user(item, column_defs)}
  elsif (2 <= (column_defs & ['Group Name', 'Category']).length)
    puts "Groups\n"
  elsif (2 <= (column_defs & ['Title', 'Groups Involved', 'Duration (in minutes)']).length)
    puts "Events\n"
  elsif (2 <= (column_defs & ['Group Name', 'User email', 'Role (Admin, Coach, Player, etc)']).length)
    puts "Users in Groups\n"
  else
    puts "Don't know what to do with sheet " + fname + "\n"
  end
  apci_session.logout
}

def balla
  puts 'stuff'
end