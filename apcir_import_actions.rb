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

  def interactive_node_owner
    owner_email = ask("Email for the owner of imported nodes:  ") {}
    user = user_list({:mail => owner_email})
    if !user.empty? && user.has_key?('item') && !user['item'].first['uid'].empty?
      @node_owner_uid = user['item'].first['uid']
      say 'Found ' + owner_email + ' at UID: ' + @node_owner_uid.to_s
      return true
    else
      puts owner_email + ' not found, try importing again.'
      return false
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
    elsif (name == 'Groups' || name == 'Group Information')
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
    
    # Parent 1
    parent_1 = row.key_filter('parent_1_')
    p1_response = import_user(parent_1) unless parent_1.empty?
    #puts p1_response.to_yaml
    parent_1_email = p1_response['mail'] if p1_response.has_key?('mail')

    # Parent 2
    parent_2 = row.key_filter('parent_2_')
    p2_response = import_user(parent_2) unless parent_1.empty?
    #puts p2_response.to_yaml
    parent_2_email = p2_response['mail'] if p2_response.has_key?('mail')

    # TODO - Make sure we have 1+ parents before creating a user under 13.

    # Primary User
    participant = row.key_filter('participant_')
    participant_response = import_user(participant)
    #puts participant_response.to_yaml

    # Parent Assignment
    puts [parent_1_email, parent_2_email].to_yaml

    # Group Assignment
    group = row.key_filter('group_')
    gadd_response = import_user_group_role(group, participant_response['mail']) if participant_response.has_key?('mail')
    puts gadd_response.to_yaml
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

    # TODO - Check user (email) doesn't already exist.  Throw a useful error.
    if !row.has_key?('email_address')
      puts 'Missing email address.'
      return
    end
    
    users = self.user_list({:mail => row['email_address']})
    if (users.has_key?('item') && users['item'].first['mail'] == row['email_address'])
      puts 'User already exists: ' + users['item'].first['mail']
      return {:mail => users['item'].first['mail']}
    end

    # TODO - If under 13 & has parent, assign Allplayers.net email.
    # TODO - Parse height into feet decimal value (precision 2?).
    # TODO - Shoe size might be a disaster - string to integer...
    # TODO - Test if all fields need 0 => value pattern or just value.
    # TODO - SMS...

    more_params = {}
    more_params['field_emergency_contact_fname'] = {:'0' => {:value => row['emergency_contact_first_name']}} if row.has_key?('emergency_contact_first_name')
    more_params['field_emergency_contact_lname'] = {:'0' => {:value => row['emergency_contact_last_name']}} if row.has_key?('emergency_contact_last_name')
    more_params['field_emergency_contact_phone'] = {:'0' => {:value => row['emergency_contact_number']}} if row.has_key?('emergency_contact_number')
#    #    more_params['field_hat_size'] = {:'0' => {:value => row['hat_size']}} if row.has_key?('hat_size')
#    more_params['field_height'] = {:'0' => {:value => row['height']}} if row.has_key?('height')
#    more_params['field_pant_size'] = {:'0' => {:value => row['pant_size']}} if row.has_key?('pant_size')
#    more_params['field_school'] = {:'0' => {:value => row['school']}} if row.has_key?('school')
#    more_params['field_school_grade'] = {:'0' => {:value => row['grade']}} if row.has_key?('grade')
#    more_params['field_shoe_size'] = {:'0' => {:value => row['shoe_size']}} if row.has_key?('shoe_size')
#    #    more_params['field_size'] = {:'0' => {:value => row['shirt_size']}} if row.has_key?('shirt_size')
#    more_params['field_weight'] = {:'0' => {:value => row['weight']}} if row.has_key?('weight')
    
    location = {}
    location['street'] =  row['primary_address_1'] if row.has_key?('primary_address_1')
    location['additional'] =  row['primary_address_2'] if row.has_key?('primary_address_2')
    location['city'] =  row['primary_city'] if row.has_key?('primary_city')
    #location['province'] =  row['primary_state'] if row.has_key?('primary_state')
    location['postal_code'] =  row['primary_zip'] if row.has_key?('primary_zip')
    location['country'] =  row['primary_country'] if row.has_key?('primary_country')
    more_params['locations'] = {:'0' => location} unless location.empty?

    emergency_contact_location = {}
    emergency_contact_location['street'] =  row['emergency_contact_address_1'] if row.has_key?('emergency_contact_address_1')
    emergency_contact_location['additional'] =  row['emergency_contact_address_2'] if row.has_key?('emergency_contact_address_2')
    emergency_contact_location['city'] =  row['emergency_contact_city'] if row.has_key?('emergency_contact_city')
    #emergency_contact_location['province'] =  row['emergency_contact_state'] if row.has_key?('emergency_contact_state')
    emergency_contact_location['postal_code'] =  row['emergency_contact_zip'] if row.has_key?('emergency_contact_zip')
    emergency_contact_location['country'] =  row['emergency_contact_country'] if row.has_key?('emergency_contact_country')
    more_params['field_emergency_contact'] = {:'0' => emergency_contact_location} unless emergency_contact_location.empty?

#    puts [
#      row['email_address'],
#      row['first_name'],
#      row['last_name'],
#      row['gender'],
#      Date.parse(row['birthdate']),
#      more_params,
#    ].to_yaml
    
    self.user_create(
      row['email_address'],
      row['first_name'],
      row['last_name'],
      row['gender'],
      Date.parse(row['birthdate']),
      more_params
    )
  ensure
    #log stuff!!
  end

  def import_group(row)
    # TODO - Seperate this out.
    # Convert everything to a string and strip whitespace.
    row.each { |key,value| row.store(key,value.to_s.strip)}
    # Delete empty values.
    row = row.delete_if { |key,value| value.empty? }
    
    # If importing to existing NID, just return spreadsheet values.
    if row.has_key?('group_nid')
      return {:title => row['group_name'], :nid => row['group_nid']}
    end

    # TODO - Assign owner uid/name to group. Seperate this...
    uid = nil
    owner = {:name => ''}

    if !@node_owner_uid
      interactive_node_owner
      if !@node_owner_uid
        puts 'Group import requires group owner'
        return {}
      else
        uid = @node_owner_uid
        owner = self.user_get(uid)
      end
    end

    more_params = {
      :uid => uid.to_s,
      :name => owner['name'],
    }
  
    # TODO - Warn before creating duplicate named groups.

    # TODO - Group Above
    if row.has_key?('group_above') && !row['group_above'].empty?
      # Lookup group by name (and group owner if possible)
      nodes = node_list({
          :type => 'group',
          :title => row['group_above'],
        })
      if nodes.has_key?('item') && nodes['item'].length == 1
        more_params['field_group'] = {:nid => {:nid=> nodes['item'].first['nid'].to_s}}
      else
        puts "Couldn't find group above: " + row['group_above']
        return
      end
    end

    location = {}
    location['street'] =  row['group_address_1'] if row.has_key?('group_address_1')
    location['additional'] =  row['group_address_2'] if row.has_key?('group_address_2')
    location['city'] =  row['group_city'] if row.has_key?('group_city')
    #location['province'] =  row['group_state'] if row.has_key?('group_state')
    location['postal_code'] =  row['group_zip'] if row.has_key?('group_zip')
    location['country'] =  row['group_country'] if row.has_key?('group_country')

    # Set Custom type, if 'Other' type.
    type = row['group_type'].split(':') unless row['group_type'].nil?
    if type
      if (type[1] && type[0].downcase == 'other')
        more_params.merge!({:spaces_preset_other => type[1]})
      end
    else
      puts 'Group Type required for group import.'
      return {}
    end

    response = self.group_create(
      row['group_name'], # Title
      row['group_description'], # Description field
      location,
      row['group_category'].strip.split(', '), # Category, comma seperated as needed. TODO - Only return the first, because it's required and the second doesn't work.
      type[0], # Spaces preset.
      more_params
    )

    if (response && response.has_key?('nid'))
      uid = @node_owner_uid
      nid = response['nid']
      #Join owner and assign admin role
      join_response = self.user_join_group(@node_owner_uid, nid)

      # Get a rid to assign.
      rid = nil
      roles = self.group_roles_list(nid)

      roles['item'].each do | role |
        if role['name'] == 'Admin'
          rid = role['rid']
          break
        end
      end

      role_response = self.user_group_role_add(@node_owner_uid, nid, rid) unless rid.nil?
    else
      puts 'Group creation failed.'
    end
    response
  ensure
    puts response.to_yaml
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

  def import_user_group_role(row, email, owner = '', nid = nil)
    # Lookup UID by email.
    uid = self.user_list({:mail => email})['item'].first['uid']

    if nid.nil?
      # Lookup group by name (and group owner if possible)
      nodes = node_list({
          :type => 'group',
          :title => row['name'],
        })
      if nodes.has_key?('item') && nodes['item'].length == 1
        nid = nodes['item'].first['nid']
      else
        puts "Couldn't find group: " + row['name'] + ' for: ' + email
        return
      end
    end


    # Join the group.
    join_response = self.user_join_group(uid, nid)

    # Get a rid to assign.
    rid = nil
    roles = self.group_roles_list(nid)

    roles['item'].each do | role |
      if role['name'] == row['role']
        rid = role['rid']
        break
      end
    end

    response = self.user_group_role_add(uid, nid, rid) unless rid.nil?

    #log stuff!!
  end
end
