# Provides ImportActions designed to extend APCI API with spreadsheet import
# tools.  Also, provides other handy tools for dealing with spreadsheets.

require 'rubygems'
require 'highline/import'
require 'active_support'
require 'apci_field_mapping'
require 'active_support/core_ext/time/conversions.rb'

# Stop EOF errors in Highline
HighLine.track_eof = false

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
  def key_filter(pattern, replacement = '')
    hsh = {}
    filtered = self.reject { |key,value| key.match(pattern).nil? }
    filtered.each { |key,value| hsh[key.sub(pattern, replacement)] = value }
    hsh
  end
end

class Date
  def to_age
    now = Time.now.utc.to_date
    now.year - self.year - ((now.month > self.month || (now.month == self.month && now.day >= self.day)) ? 0 : 1)
  end
end

# Functions to aid importing any type of spreadsheet to Allplayers.com.
module ImportActions

  def interactive_login(user = nil, pass = nil)
    if @session_cookies.empty?
      user = ask("Enter your Allplayers.com e-mail / user:  ") { |q| q.echo = true } if user.nil?
      pass = ask("Enter your Allplayers.com password:  ") { |q| q.echo = false } if pass.nil?
      self.login( user, pass )
    else
      puts 'Already logged in?'
    end
  rescue RestClient::Exception => e
    pass = nil
    retry
  end

  def interactive_node_owner
    email = ask("Email for the owner of imported nodes:  ") { |q| q.echo = true }
    begin
      uid = email_to_uid(email)
    rescue
      puts 'Error locating user: ' + email
      raise
    end
  rescue
    email = nil
    retry
  else
    if uid.nil?
      raise
    end
    @node_owner_email = email unless uid.nil?
    uid
  end


  def email_to_uid(email)
    # 'Static' cache
    @uid_map = Hash.new unless defined? @uid_map
    if !@uid_map.has_key?(email)
      users = self.user_list({:mail => email})
      if users.has_key?('item') && users['item'].length == 1
        @uid_map[email] = users['item'].first['uid']
      else
        raise
      end
    end
    @uid_map[email]
  rescue
    raise
  end

  def group_name_to_nid(name)
    # Lookup group by name
    # TODO - Extend to filter by group owner, too.  Reduce chance of mismatch.
    nodes = node_list({
        :type => 'group',
        :title => name,
      })
    if nodes.has_key?('item') && nodes['item'].length == 1
      return nodes['item'].first['nid']
    else
      raise
    end
  end

  def group_role_to_rid(role_name, nid)
    roles = self.group_roles_list(nid)

    roles['item'].each do | role |
      if role['name'] == role_name && role.has_key?('rid')
        return role['rid']
      end
    end
    # Didn't find group role.
    raise
  end

  def prepare_row(row_array, column_defs)
    @row_count = 1 unless @row_count
    @row_count+=1
    puts 'Row ' + @row_count.to_s + ': Processing'
    row = row_array.to_hash(column_defs)
    # Convert everything to a string and strip whitespace.
    row.each { |key,value| row.store(key,value.to_s.strip)}
    # Delete empty values.
    row.delete_if { |key,value| value.empty? }
  end

  def increment_stat(type)
    if @stats.has_key?(type)
      @stats[type]+=1
    else
      @stats[type] = 1
    end
  end

  def import_sheet(sheet, name)
    @stats = {}
    start_time = Time.now

    @row_count = 1
    # Pull the first row and chunk it, it's just extended field descriptions.
    puts 'Row ' + @row_count.to_s + ": Skipping Descriptions"
    sheet.shift

    # Pull the second row and use it to define columns.
    @row_count += 1
    puts 'Row ' + @row_count.to_s + ": Parsing column labels"
    begin
      column_defs = sheet.shift.split_first("\n").gsub(/[^0-9a-z]/i, '_').downcase
    rescue
      puts 'Row ' + @row_count.to_s + ": Error parsing column labels"
      return
    end

    # TODO - Detect sheet type / sanity check by searching column_defs
    if (name == 'Participant Information')
      # mixed sheet... FUN!
      puts 'Row ' + @row_count.to_s + ": Importing Participants, Parents and Group assignments\n"
      sheet.each {|row| self.import_mixed_user(self.prepare_row(row, column_defs))}
    elsif (name == 'Bad Participant Information')
      # mixed sheet... FUN!
      puts 'Row ' + @row_count.to_s + ": Importing Participants, Parents and Group assignments\n"
      sheet.each {|row| self.import_bad_mixed_user(self.prepare_row(row, column_defs))}
    elsif (name == 'Users')
      #if (2 <= (column_defs & ['First Name', 'Last Name']).length)
      puts 'Row ' + @row_count.to_s + ": Importing Users\n"
      sheet.each {|row| self.import_user(self.prepare_row(row, column_defs))}
    elsif (name == 'Groups' || name == 'Group Information')
      #elsif (2 <= (column_defs & ['Group Name', 'Category']).length)
      puts 'Row ' + @row_count.to_s + ": Importing Groups\n"
      return unless interactive_node_owner
      sheet.each {|row| self.import_group(self.prepare_row(row, column_defs))}
    elsif (name == 'Events')
      #elsif (2 <= (column_defs & ['Title', 'Groups Involved', 'Duration (in minutes)']).length)
      puts 'Row ' + @row_count.to_s + ": Importing Events\n"
      sheet.each {|row| self.import_event(self.prepare_row(row, column_defs))}
    elsif (name == 'Users in Groups')
      #elsif (2 <= (column_defs & ['Group Name', 'User email', 'Role (Admin, Coach, Player, etc)']).length)
      puts 'Row ' + @row_count.to_s + ": Importing Users in Groups\n"
      sheet.each {|row| self.import_user_group_role(self.prepare_row(row, column_defs))}
    else
      puts 'Row ' + @row_count.to_s + ": Don't know what to do with sheet " + name + "\n"
      next # Go to the next sheet.
    end
    # Output stats
    seconds = (Time.now - start_time).to_i
    stats_array = []
    @stats.each { |key,value| stats_array.push(key.to_s + ': ' + value.to_s) unless value.nil? or value == 0}
    puts
    puts @row_count.to_s + ' rows processed.'
    puts
    puts 'Imported ' + stats_array.sort.join(', ')
    puts ' in ' + (seconds / 60).to_s + ' minutes ' + (seconds % 60).to_s + ' seconds.'
    puts
    # End stats
  end

  def import_mixed_user(row)
    # Import Users (Make sure parents come first).
    responses = {}
    ['parent_1_', 'parent_2_',  'participant_'].each {|prefix|
      user = row.key_filter(prefix)
      # Add in Parent email addresses if this is the participant.
      user.merge!(row.reject {|key, value|  !key.include?('email_address')}) if prefix == 'participant_'
      description = prefix.split('_').join(' ').strip.capitalize

      responses[prefix] = import_user(user, description) unless user.empty?
    }

    if responses.has_key?('participant_') && !responses['participant_'].nil?
      # Update participant with responses.  We're done with parents.
      row['participant_uid'] = responses['participant_']['uid'] if responses['participant_'].has_key?('uid')
      row['participant_email_address'] = responses['participant_']['mail'] if responses['participant_'].has_key?('mail')
      
      # Find the max number of groups being imported
      group_list = row.reject {|key, value| key.match('group_').nil?}
      number_of_groups = 0
      key_int_value = 0
      group_list.each {|key, value|
        key_parts = key.split('_')        
        key_parts.each {|part|
          key_int_value = part.to_i
          if (key_int_value > number_of_groups)
            number_of_groups = key_int_value
          end
        }
      }
      puts 'Row ' + @row_count.to_s + ': Max number of groups: ' + number_of_groups.to_s
      
      # Create the list of group names to iterate through
      group_names = []
      for i in 1..number_of_groups
        group_names.push('group_' + i.to_s + '_')
      end

      # Group Assignment + Participant
      # TODO - Create per session Group title - NID (email - UID too?) map to prefer nodes created.
      #['group_1_', 'group_2_', 'group_3_'].each {|prefix|
      group_names.each {|prefix|
        group = row.key_filter(prefix, 'group_')
        user = row.key_filter('participant_')
        responses[prefix] = import_user_group_role(user.merge(group)) unless group.empty?
      }
    end
    puts '---'
  end

  def import_bad_mixed_user(row)
    # Import Users (Make sure parents come first).
    responses = {}
#    ['parent_1_', 'parent_2_',  'participant_'].each {|prefix|
#      user = row.key_filter(prefix)
#      # Add in Parent email addresses if this is the participant.
#      user.merge!(row.reject {|key, value|  !key.include?('email_address')}) if prefix == 'participant_'
#      description = prefix.split('_').join(' ').strip.capitalize
#
#      responses[prefix] = import_user(user, description) unless user.empty?
#    }

#    if responses.has_key?('participant_') && !responses['participant_'].nil?
#      # Update participant with responses.  We're done with parents.
#      row['participant_uid'] = responses['participant_']['uid'] if responses['participant_'].has_key?('uid')
#      row['participant_email_address'] = responses['participant_']['mail'] if responses['participant_'].has_key?('mail')

      # Find the max number of groups being imported
      group_list = row.reject {|key, value| key.match('group_').nil?}
      number_of_groups = 0
      key_int_value = 0
      group_list.each {|key, value|
        key_parts = key.split('_')
        key_parts.each {|part|
          key_int_value = part.to_i
          if (key_int_value > number_of_groups)
            number_of_groups = key_int_value
          end
        }
      }
      puts 'Row ' + @row_count.to_s + ': Max number of groups: ' + number_of_groups.to_s

      # Create the list of group names to iterate through
      group_names = []
      for i in 1..number_of_groups
        group_names.push('group_' + i.to_s + '_')
      end

      # Group Assignment + Participant
      # TODO - Create per session Group title - NID (email - UID too?) map to prefer nodes created.
      #['group_1_', 'group_2_', 'group_3_'].each {|prefix|
      group_names.each {|prefix|
        group = row.key_filter(prefix, 'group_')
        user = row.key_filter('participant_')
#        responses[prefix] = import_user_group_role(user.merge(group)) unless group.empty?
        responses[prefix] = remove_user_group_role(user.merge(group)) unless group.empty?
      }
#    end
    puts '---'
  end

=begin
# implies Implemented
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
- home_phone
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
  def import_user(row, description = 'User')
    more_params = {}

    birthdate = Date.parse(row['birthdate'])

    if birthdate.to_age < 21
      begin
        # Verify parents and get UIDs
        row['parent_1_uid'] = self.email_to_uid(row['parent_1_email_address']) if row.has_key?('parent_1_email_address')
      rescue
        puts 'Row ' + @row_count.to_s + ": Can't find account for Parent 1 : " + row['parent_1_email_address']
      end
      begin
        row['parent_2_uid'] = self.email_to_uid(row['parent_2_email_address']) if row.has_key?('parent_2_email_address')
      rescue
        puts 'Row ' + @row_count.to_s + ": Can't find account for Parent 2 : " + row['parent_2_email_address']
      end
    end

    # If 13 or under, verify parent, request allplayers.net email if needed.
    if birthdate.to_age < 14
      # If 13 or under, no email  & has parent, request allplayers.net email.
      if !(row.has_key?('parent_1_uid') || row.has_key?('parent_2_uid'))
        puts 'Row ' + @row_count.to_s + ': Missing parents for '+ description +' age 13 or less.'
        return {}
      end
    end

    # Request allplayers.net email if needed.
    if !row.has_key?('email_address')
      # If 13 or under, no email  & has parent, request allplayers.net email.
      if row.has_key?('parent_1_uid') || row.has_key?('parent_2_uid')
        # Request allplayers.net email
        # TODO - Avoid creating duplicate children.
        # TODO - Consider how to send welcome email to parent.
        more_params['email_alternative'] = {:value => 1}
      else
        puts 'Row ' + @row_count.to_s + ': Missing parents for '+ description +' without email address.'
        return {}
      end
    elsif
      # Check if user already exists
      uid = email_to_uid(row['email_address']) rescue false
      if uid
        puts 'Row ' + @row_count.to_s + ': ' + description +' already exists: ' + row['email_address'] + ' at UID: ' + uid + '. No profile fields will be imported.  Participant will still be added to groups.'
        return {:mail => row['email_address'], :uid => uid }
      end
    end

    # Check required fields
    missing_fields = ['first_name', 'last_name', 'gender', 'birthdate'].reject {
      |field| row.has_key?(field) && !row[field].nil? && !row[field].empty?
    }
    if !missing_fields.empty?
      puts 'Row ' + @row_count.to_s + ': Missing required fields for '+ description +': ' + missing_fields.join(', ')
      return {}
    end

    puts 'Row ' + @row_count.to_s + ': Importing ' + description +': ' + row['first_name'] + ' ' + row['last_name']

    # TODO - Parse height into feet decimal value (precision 2?).
    # TODO - Shoe size might be a disaster - string to integer...
    # TODO - Test if all fields need 0 => value pattern or just value.

    more_params['field_emergency_contact_fname'] = {:'0' => {:value => row['emergency_contact_first_name']}} if row.has_key?('emergency_contact_first_name')
    more_params['field_emergency_contact_lname'] = {:'0' => {:value => row['emergency_contact_last_name']}} if row.has_key?('emergency_contact_last_name')
    more_params['field_emergency_contact_phone'] = {:'0' => {:value => row['emergency_contact_number']}} if row.has_key?('emergency_contact_number')
    more_params['field_hat_size'] = {:'0' => {:value => row['hat_size']}} if row.has_key?('hat_size')
    more_params['field_height'] = {:'0' => {:value => apci_field_height(row['height'])}} if row.has_key?('height')
    more_params['field_pant_size'] = {:'0' => {:value => row['pant_size']}} if row.has_key?('pant_size')
    more_params['field_phone'] = {:'0' => {:value => row['home_phone']}} if row.has_key?('home_phone')
    more_params['field_school'] = {:'0' => {:value => row['school']}} if row.has_key?('school')
    more_params['field_school_grade'] = {:'0' => {:value => row['grade']}} if row.has_key?('grade')
    more_params['field_shoe_size'] = {:'0' => {:value => apci_field_shoe_size(row['shoe_size'])}} if row.has_key?('shoe_size')
    more_params['field_size'] = {:'0' => {:value => apci_field_shirt_size(row['shirt_size'])}} if row.has_key?('shirt_size')
    more_params['field_weight'] = {:'0' => {:value => row['weight']}} if row.has_key?('weight')
    more_params['field_organization'] = {:'0' => {:value => row['organization']}} if row.has_key?('organization')

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

    response = self.user_create(
      row['email_address'],
      row['first_name'],
      row['last_name'],
      row['gender'],
      birthdate,
      more_params
    )
  rescue RestClient::Exception => e
    puts 'Row ' + @row_count.to_s + ': Failed to import ' + description
  rescue ArgumentError => err
    puts 'Row ' + @row_count.to_s + ': Invalid Birth Date.  Failed to import ' + description
    puts err.to_yaml
    #rescue
    #  puts 'Row ' + @row_count.to_s + ': Unknown Error.  Failed to import ' + description
  else
    if !response.nil?
      increment_stat('Users')
      increment_stat(description + 's') if description != 'User'
      response['parenting_1_response'] = self.user_parent_add(response['uid'], row['parent_1_uid']) if row.has_key?('parent_1_uid')
      response['parenting_2_response'] = self.user_parent_add(response['uid'], row['parent_2_uid']) if row.has_key?('parent_2_uid')
      return response
    end
    #log stuff!!
  end

  def import_group(row)
    # If importing to existing NID, just return spreadsheet values.
    if row.has_key?('group_nid')
      return {:title => row['group_name'], :nid => row['group_nid']}
    end

    # Assign owner uid/name to group.
    # TODO - Move node ownership into the apci_rest library.  All nodes should
    # have an owner, generally not admin.
    if @node_owner_email
      begin
        uid = email_to_uid(@node_owner_email)
        owner = self.user_get(uid)
        raise if !owner.has_key?('name')
      rescue
        puts "Couldn't get group owner: " + @node_owner_email
        return {}
      end
    else
      puts 'Group import requires group owner'
      return {}
    end

    more_params = {
      :uid => uid.to_s,
      :name => owner['name'],
    }

    # TODO - Warn before creating duplicate named groups.

    # Group Above
    # TODO - Move node searching into a separate function.
    if row.has_key?('group_above') && !row['group_above'].empty?
      # Lookup group by name (and group owner if possible)
      nodes = node_list({
          :type => 'group',
          :title => row['group_above'],
        })
      if nodes.has_key?('item') && nodes['item'].length == 1
        puts 'Row ' + @row_count.to_s + ': Found group above: ' + row['group_above'] + 'at NID ' + nodes['item'].first['nid'].to_s
        more_params['field_group'] = {'0' => {'nid' => nodes['item'].first['nid'].to_s}}
      else
        puts 'Row ' + @row_count.to_s + "Couldn't find group above: " + row['group_above']
        return
      end
    end

    # TODO - Move location handling to separate function.
    location = {}
    location['street'] =  row['group_address_1'] if row.has_key?('group_address_1')
    location['additional'] =  row['group_address_2'] if row.has_key?('group_address_2')
    location['city'] =  row['group_city'] if row.has_key?('group_city')
    location['province'] =  row['group_state'] if row.has_key?('group_state')
    location['postal_code'] =  row['group_zip'] if row.has_key?('group_zip')
    # See Drupal location.module.  Province requires country.
    if row.has_key?('group_country')
      location['country'] =  row['group_country']
    elsif location.has_key?('province')
      location['country'] = 'us'
    end

    # Set Custom type, if 'Other' type.
    # TODO - Move this into apci_rest
    type = row['group_type'].split(':') unless row['group_type'].nil?
    if type
      if (type[1] && type[0].downcase == 'other')
        more_params.merge!({:spaces_preset_other => type[1]})
      end
    else
      puts 'Group Type required for group import.'
      return {}
    end

    puts 'Row ' + @row_count.to_s + ': Importing group: ' + row['group_name']

    response = self.group_create(
      row['group_name'], # Title
      row['group_description'], # Description field
      location,
      row['group_category'].strip.split(', '), # Category, comma separated as needed. TODO - Only return the first, because it's required and the second doesn't work.
      type[0], # Spaces preset.
      more_params
    )
  rescue RestClient::Exception => e
    puts 'Row ' + @row_count.to_s + ': Failed to import group'
  else
    #log stuff!!
    if (response && response.has_key?('nid'))
      increment_stat('Groups')
      @group_nid_map = Hash.new unless defined? @group_nid_map
      @group_nid_map[row['group_name']] = response['nid']

      # Assign Owner.
      owner_group = {}
      owner_group['uid'] = uid.to_s
      owner_group['group_nid'] = response['nid']
      owner_group['group_name'] = row['group_name']
      owner_group['group_role'] = 'Admin'
      response['owner'] = import_user_group_role(owner_group)
    end
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
    # Check User.
    if row.has_key?('uid')
      uid = row['uid']
    elsif row.has_key?('email_address')
      begin
        uid = email_to_uid(row['email_address'])
      rescue
        puts 'Row ' + @row_count.to_s + ": User " + row['email_address'] + " doesn't exist to add to group " + row['group_name'] + "."
        return
      end
    else
      puts 'Row ' + @row_count.to_s + ": User can't be added to group without email address."
      return
    end

    # Check Group
    if row.has_key?('group_nid')
      nid = row['group_nid']
    elsif row.has_key?('group_name')
      begin
        nid = group_name_to_nid(row['group_name'])
      rescue
        puts 'Row ' + @row_count.to_s + ": Can't locate group " + row['group_name']
        return
      end
    else
      puts 'Row ' + @row_count.to_s + ': User ' + row['email_address'] + " can't be added to group without group name."
      return
    end

    response = {}
    # Join user to group.
    response['join'] = self.user_join_group(uid, nid)

    # Add to user to group role
    # TODO - Split group role assignment to separate function.
    if row.has_key?('group_role')
      # Break up any comma separated list of roles into individual roles
      group_roles_array = []
      group_roles_array = group_roles_array + row['group_role'].split(',')
      group_roles_array.each {|element|
        group_role = element.strip
        
        # Get a rid to assign.
        begin
          rid = group_role_to_rid(group_role, nid)
        rescue
          row_count = @row_count.to_s.nil? ? 'NIL-ROW-NUMBER' : @row_count.to_s
          group_role = group_role.nil? ? 'NIL-GROUP-ROLE' : group_role
          group_name = row['group_name'].nil? ? 'NIL-GROUP-NAME' : row['group_name']
          #puts 'Row ' + @row_count.to_s + ": Can't locate role " + group_role + ' in group ' + row['group_name']
          puts 'Row ' + row_count + ": Can't locate role " + group_role + ' in group ' + group_name
        end
        response['role'] = self.user_group_role_add(uid, nid, rid) unless rid.nil?
      }
    end

    #log stuff!!

    response
  end

  def remove_user_group_role(row)
    # Check User.
    if row.has_key?('uid')
      uid = row['uid']
    elsif row.has_key?('email_address')
      begin
        uid = email_to_uid(row['email_address'])
      rescue
        puts 'Row ' + @row_count.to_s + ": User " + row['email_address'] + " doesn't exist to add to group " + row['group_name'] + "."
        return
      end
    else
      puts 'Row ' + @row_count.to_s + ": User can't be added to group without email address."
      return
    end

    # Check Group
    if row.has_key?('group_nid')
      nid = row['group_nid']
    elsif row.has_key?('group_name')
      begin
        nid = group_name_to_nid(row['group_name'])
      rescue
        puts 'Row ' + @row_count.to_s + ": Can't locate group " + row['group_name']
        return
      end
    else
      puts 'Row ' + @row_count.to_s + ': User ' + row['email_address'] + " can't be added to group without group name."
      return
    end

    response = {}
    puts 'Row ' + @row_count.to_s + ': User ' + uid.to_s + " removed from group " + nid.to_s
    # Join user to group.
    response['leave'] = self.user_leave_group(uid, nid)

    puts response['leave'].to_yaml

    #log stuff!!

    response
  end
end
