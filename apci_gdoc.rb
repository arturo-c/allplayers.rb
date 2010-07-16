#!/usr/bin/ruby
# to run: ruby get_csv.php filename tab_id
require 'rubygems'
require 'gdata'
require 'fastercsv'

class ApciGoogSS
  def initialize
    @client = GData::Client::DocList.new
  end

  def login(user, pass)
    @client.clientlogin(user, pass)
  rescue
    puts "Login failed: " + $!
  end

  def get_from_csv(key, tab)
    feed = @client.get("http://spreadsheets.google.com/pub?key=#{key}&single=true&gid=#{tab}&output=csv")
    FasterCSV.parse(feed.body, {:converters => :all} )
  rescue
    puts "Failed to get spreadsheet CSV.  Did you publish the sheet?\n"
    puts $!
  end
end


class Array
  # Little utility to convert array to Hash with defined keys.
  def to_hash(other)
    Hash[ *(0...other.size()).inject([]) { |arr, ix| arr.push(other[ix], self[ix]) } ]
  end
  # Split off first element in each array item.
  def split_first(pattern)
    arr = []
    self.length.times do |i|
      arr.push(self[i].split(pattern)[0])
    end
    arr
  end
end

# Functions to aid importing any type of spreadsheet.
module ImportActions
  def import_sheet(sheet, name)
    # Take the first row and use it to define columns.  Use only the first line.
    column_defs = sheet.shift.split_first("\n")

    # Detect sheet type / Sanity Check
    #if (2 <= (column_defs & ['First Name', 'Last Name']).length)
    if (name == 'Users')
      sheet.each {|row| self.import_user(row.to_hash(column_defs))}
    elsif (2 <= (column_defs & ['Group Name', 'Category']).length)
      puts "Importing Groups\n"
      sheet.each {|row| self.import_user(row.to_hash(column_defs))}
    elsif (2 <= (column_defs & ['Title', 'Groups Involved', 'Duration (in minutes)']).length)
      puts "Events: not implemented\n"
    elsif (2 <= (column_defs & ['Group Name', 'User email', 'Role (Admin, Coach, Player, etc)']).length)
      puts "Users in Groups: not implemented\n"
    else
      puts "Don't know what to do with sheet " + fname + "\n"
      next
    end
  end

  def import_user(row)
    more_params = {}
    self.user_create(
      row['mail'],
      row['field_firstname'],
      row['field_lastname'],
      row['field_gender'],
      Date.parse(row['field_birth_date']),
      more_params
    )
    #log stuff!!
  end

  def import_group(row)
    # @TODO - Assign owner uid/name to group.
    more_params = {}
    self.group_create(
      row['mail'],
      'password',
      row['field_firstname'],
      row['field_lastname'],
      row['field_gender'],
      Date.parse(row['field_birth_date']),
      more_params
    )
    #log stuff!!
  end

  def import_events(row)
    # @TODO - Assign owner uid/name to event.
    row['event_group_names'] # Lookup group assignments.

    # Get appropriate Taxonomy term.
    vid = self.taxonomy_vocabulary_list({:module => 'features_event_category'})['item']['vid']
    tid = self.taxonomy_term_list({:name => row['category'], :vid => vid})['item']['tid']

    start_date = Date.parse(row['start_date_time'])
    end_date = Date.parse(row['end_date_time'])

    more_params = {}
    self.node_create(
      row['event_title'],
      row['field_firstname'],
      row['field_lastname'],
      row['field_gender'],
      Date.parse(row['field_birth_date']),
      more_params
    )
    #log stuff!!
  end

  def import_user_group_role(row)
    # Lookup group by name (and group owner)
    # Lookup UID by email.
    uid = self.user_list({:mail => row['user_email']})['item']['uid']
    # Lookup role name
    more_params = {}
    self.group_create(
      row['mail'],
      'password',
      row['field_firstname'],
      row['field_lastname'],
      row['field_gender'],
      Date.parse(row['field_birth_date']),
      more_params
    )
    #log stuff!!
  end
end