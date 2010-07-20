#!/usr/bin/ruby
# to run: ruby get_csv.php filename tab_id
require 'rubygems'
require 'gdata'
require 'fastercsv'
# Hash.from_xml()
require 'active_support'
require "addressable/uri"
require 'highline/import'

class ApciGoogSS
  def initialize(protocol = 'https')
    @client = GData::Client::Spreadsheets.new
    @base_uri = Addressable::URI.parse(protocol +'://spreadsheets.google.com/')
    #@headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
  end

  def login(user, pass)
    begin
      @client.clientlogin(user, pass)
      rescue GData::Client::AuthorizationError
        $dz.error("Login Failure", "Something went wrong while logging you in. Check the credentials")
      rescue GData::Client::CaptchaError
        $dz.error("Login Failure", "There was an error during login, try to login to Google Docs in your browser and then try again.")
      rescue SocketError
        $dz.error("No connection", "Cannot connect to the Google Docs service, are you connected to the internet?")
      rescue Exception
        $dz.error("Unkown error", "An unkown error happened.")
    else
      sleep(1)
    end
  end

  def interactive_login
    user = ask("Enter your Google Docs e-mail:  ") { }
    pass = ask("Enter your Google Docs password:  ") { |q| q.echo = false }
    self.login( user, pass )
  end

  def list
    uri = @base_uri.join('feeds/spreadsheets/private/full')
    feed = @client.get(uri)
    Hash.from_xml(feed.body)
  rescue
    puts "Unable to list spreadsheets: " + $!
  end

  def get_content(href)
    # TODO - Honor SSL/HTTPS...
    #uri = @base_uri.join('feeds/spreadsheets/private/full')
    uri = Addressable::URI.parse(href)
    feed = @client.get(uri)
    Hash.from_xml(feed.body)
  rescue
    puts "Unable to retrieve spreadsheet: " + $!
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
  def interactive_login
    if @session_cookies.empty?
      user = ask("Enter your Allplayers.com e-mail / user:  ") { }
      pass = ask("Enter your Allplayers.com password:  ") { |q| q.echo = false }
      self.login( user, pass )
    else
      puts 'Already logged in?'
    end
  end

  def import_sheet(sheet, name)
    # Take the first row and use it to define columns.  Use only the first line.
    column_defs = sheet.shift.split_first("\n")

    # TODO - Detect sheet type / Sanity Check
    if (name == 'Users')
      #if (2 <= (column_defs & ['First Name', 'Last Name']).length)
      puts "Importing Users\n"
      sheet.each {|row| self.import_user(row.to_hash(column_defs))}
    elsif (name == 'Groups')
      #elsif (2 <= (column_defs & ['Group Name', 'Category']).length)
      puts "Importing Groups\n"
      sheet.each {|row| self.import_group(row.to_hash(column_defs))}
    elsif (name == 'Events')
      #elsif (2 <= (column_defs & ['Title', 'Groups Involved', 'Duration (in minutes)']).length)
      puts "Importing Events\n"
      sheet.each {|row| self.import_event(row.to_hash(column_defs))}
    elsif (name == 'Users in Groups')
      #elsif (2 <= (column_defs & ['Group Name', 'User email', 'Role (Admin, Coach, Player, etc)']).length)
      puts "Importing Users in Groups\n"
      sheet.each {|row| self.import_user_group_role(row.to_hash(column_defs))}
    else
      puts "Don't know what to do with sheet " + fname + "\n"
      next # Go to the next sheet.
    end
  end

  def import_user(row)

    puts 'Importing Users'
    #return

    more_params = {}
    self.user_create(
      row['mail'],
      row['firstname'],
      row['lastname'],
      row['gender'],
      Date.parse(row['birth_date']),
      more_params
    )
    #log stuff!!
  end

  def import_group(row)
    more_params = {}

    # TODO - Assign owner uid/name to group.
    # TODO - Group Above

    location = {
      :street => row['address_1'],
      :additional => row['address_2'],
      :city => row['city'],
      :province => row['state_province'],
      :postal_code => row['postal_code'],
      }

    # Set Custom type, if 'Other' type.
    type = row['type'].split(':')
    if (type[1] && type[0].downcase == 'other')
      more_params.merge!({:spaces_preset_other => type[1]})
    end

    puts self.group_create(
     row['group_name'], # Title
     row['description'], # Description field
     location,
     row['category'].split(', '), # Category, comma seperated as needed.
     type[0], # Spaces preset.
     more_params
    ).to_yaml
    #log stuff!!
  end

  def import_event(row)
    puts row.to_yaml
    return
    
    # TODO - Assign owner uid/name to event.
    groups = row['event_group_names'] # TODO - Lookup group assignments.

    # Placeholder for additional fields.
    more_params = {}
    
    self.event_create(
      row['event_title'],
      groups,
      Date.parse(row['start_date_time']),
      Date.parse(row['end_date_time']),
      row['event_title'],
      row['description'],
      more_params
    )
    #log stuff!!
  end

  def import_user_group_role(row)
    puts row.to_yaml
    return

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
