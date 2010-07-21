# Provides ImportActions designed to extend APCI API with spreadsheet import
# tools.  Also, provides other handy tools for dealing with spreadsheets.

require 'rubygems'
require 'highline/import'
require 'active_support'

# Add some tools to Array to make parsing spreadsheet rows easier.
class Array
  # Little utility to convert array to Hash with defined keys.
  def to_hash(other)
    Hash[ *(0...other.size()).inject([]) { |arr, ix| arr.push(other[ix], self[ix]) } ]
  end
  # Split off first element in each array item, after splitting by pattern, then
  # strip trailing and preceding whitespaces.
  def split_first(pattern)
    arr = []
    self.each do | item |
      arr.push(item.split(pattern)[0])
    end
    arr
  end
  def downcase
    arr = []
    self.each do |item|
      arr.push(item.downcase)
    end
    arr
  end
  def gsub(pattern,replacement)
    arr = []
    self.each do |item|
      arr.push(item.gsub(pattern,replacement))
    end
    arr
  end
end

class Hash
  def key_filter(pattern)
    hsh = {}
    filtered = self.reject { |key,value|
      if (key.match(pattern).nil?)
        true
      else
        false
      end
    }
    filtered.each do |key,value|
      hsh[key.sub(pattern,'')] = value
    end
    hsh
  end
end

# Functions to aid importing any type of spreadsheet to Allplayers.com.
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
    # Pull the first row and chunk it, it's just extended field descriptions.
    sheet.shift
    # Pull the second row and use it to define columns.
    column_defs = sheet.shift.split_first("\n").gsub(/[^0-9a-z]/i, '_').downcase

    # TODO - Detect sheet type / sanity check by searching column_defs
    if (name == 'Participant Information')
      # mixed sheet... FUN!
      puts "Importing Users\n"
      sheet.each {|row| self.import_mixed_user(row.to_hash(column_defs))}
    elsif (name == 'Users')
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

  def import_mixed_user(row)
    # Convert everything to a string and strip whitespace.
    row.each { |key,value| row.store(key,value.to_s.strip)}
    # Delete empty values.
    row = row.delete_if { |key,value| value.empty? }
    
#    # Parent 1
#    parent_1 = row.key_filter('parent_1_')
#    p1_response = import_user(parent_1)
#    puts p1_response.to_yaml
#    # Parent 2
#    parent_2 = row.key_filter('parent_2_')
#    p2_response = import_user(parent_2)
#    puts p2_response.to_yaml
    # TODO - Make sure we have parents before creating the user.
    # Primary User
    participant = row.key_filter('participant_')
    participant_response = import_user(participant)
    puts participant_response.to_yaml
    # Parent Assignment
#    # Group Assignment
#    group = row.key_filter('group_')
#    puts group.to_yaml
  end

=begin
# means Implemented
#- birthdate
- cell_phone
- cell_phone_carrier
#- email_address
#- emergency_contact_address_1
#- emergency_contact_address_2
#- emergency_contact_city
#- emergency_contact_first_name
#- emergency_contact_last_name
#- emergency_contact_number
#- emergency_contact_state
#- emergency_contact_zip
#- first_name
#- gender
#- grade
#- hat_size
#- height
#- home_phone
#- last_name
#- pant_size
#- primary_address_1
#- primary_address_2
#- primary_city
#- primary_state
#- primary_zip
#- school
#- shirt_size
#- shoe_size
#- weight
=end
  def import_user(row)

    # TODO - Make sure user (email) doesn't already exist.
    # TODO - If under 13 & has parent, assign Allplayers.net email.
    # TODO - Parse height into feet decimal value (precision 2?).
    # TODO - Shoe size might be a disaster - string to integer...
    # TODO - Test if all fields need 0 => value pattern or just value.
    # TODO - SMS...

    more_params = {}
    more_params['field_emergency_contact_fname'] = {:'0' => {:value => row['emergency_contact_first_name']}} if row.has_key?('emergency_contact_first_name')
    more_params['field_emergency_contact_lname'] = {:'0' => {:value => row['emergency_contact_last_name']}} if row.has_key?('emergency_contact_last_name')
    more_params['field_emergency_contact_phone'] = {:'0' => {:value => row['emergency_contact_number']}} if row.has_key?('emergency_contact_number')
    more_params['field_hat_size'] = {:'0' => {:value => row['hat_size']}} if row.has_key?('hat_size')
    more_params['field_height'] = {:'0' => {:value => row['height']}} if row.has_key?('height')
    more_params['field_pant_size'] = {:'0' => {:value => row['pant_size']}} if row.has_key?('pant_size')
    more_params['field_school'] = {:'0' => {:value => row['school']}} if row.has_key?('school')
    more_params['field_school_grade'] = {:'0' => {:value => row['grade']}} if row.has_key?('grade')
    more_params['field_shoe_size'] = {:'0' => {:value => row['shoe_size']}} if row.has_key?('shoe_size')
    more_params['field_size'] = {:'0' => {:value => row['shirt_size']}} if row.has_key?('shirt_size')
    more_params['field_weight'] = {:'0' => {:value => row['weight']}} if row.has_key?('weight')
    
    location = {}
    location['street'] =  row['primary_address_1'] if row.has_key?('primary_address_1')
    location['additional'] =  row['primary_address_2'] if row.has_key?('primary_address_2')
    location['city'] =  row['primary_city'] if row.has_key?('primary_city')
    location['province'] =  row['primary_state'] if row.has_key?('primary_state')
    location['postal_code'] =  row['primary_zip'] if row.has_key?('primary_zip')
    location['country'] =  row['primary_country'] if row.has_key?('primary_country')
    more_params['locations'] = {:'0' => location} unless location.empty?

    emergency_contact_location = {}
    emergency_contact_location['street'] =  row['emergency_contact_address_1'] if row.has_key?('emergency_contact_address_1')
    emergency_contact_location['additional'] =  row['emergency_contact_address_2'] if row.has_key?('emergency_contact_address_2')
    emergency_contact_location['city'] =  row['emergency_contact_city'] if row.has_key?('emergency_contact_city')
    emergency_contact_location['province'] =  row['emergency_contact_state'] if row.has_key?('emergency_contact_state')
    emergency_contact_location['postal_code'] =  row['emergency_contact_zip'] if row.has_key?('emergency_contact_zip')
    emergency_contact_location['country'] =  row['emergency_contact_country'] if row.has_key?('emergency_contact_country')
    more_params['field_emergency_contact'] = {:'0' => emergency_contact_location} unless emergency_contact_location.empty?

    self.user_create(
      row['email_address'],
      row['first_name'],
      row['last_name'],
      row['gender'],
      Date.parse(row['birthdate']),
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
