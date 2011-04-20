#!/usr/bin/ruby
# == Synopsis
#
# test_apci_rest: Test apci_rest API.
#
# == Usage
#
# test_apci_rest [UNIT TEST OPTS] -- [OPTS] ... [USER@HOST]|[HOST]
#
# UNIT TEST OPTS:
#  Arguments before -- are sent to Unit Test runner.  See test_apci_rest --help
#  for help with these arguments.
#
# OPTS:
#  -h, --help                  show this help (ignores other options)
#  -p                          session authentication password
#
# HOST: The target server for testing REST services (e.g. demo.allplayers.com).
#
# OR use environment variables:
#
#  ENV['APCI_REST_TEST_HOST']
#  ENV['APCI_REST_TEST_USER']
#  ENV['APCI_REST_TEST_PASS']
#

# Add path to the lib directory.
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'apci_rest'
require 'apci_field_mapping'
require 'test/unit'
require 'getoptlong'
require 'rdoc/usage'
require 'logger'
require 'etc'

class TestApcirClient < Test::Unit::TestCase

  def get_args
    # If any environment variable set, skip argument handling.
    if ENV.has_key?('APCI_REST_TEST_HOST')
      $apci_rest_test_host = ENV['APCI_REST_TEST_HOST']
      $apci_rest_test_user = ENV['APCI_REST_TEST_USER']
      $apci_rest_test_pass = ENV['APCI_REST_TEST_PASS']
      return
    end

    $apci_rest_test_user = Etc.getlogin if $apci_rest_test_user.nil?
    $apci_rest_test_pass = nil if $apci_rest_test_pass.nil?

    opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '-p',       GetoptLong::REQUIRED_ARGUMENT]
    )

    opts.each do |opt, arg|
      case opt
        when '--help'
          RDoc::usage
        when '-p'
          $apci_rest_test_pass = arg
      end
    end

    RDoc::usage if $apci_rest_test_pass.nil?

    # Handle default argument => host to target for import and optional user,
    # (i.e. user@sandbox.allplayers.com).
    if ARGV.length != 1
      puts "No host argument, connecting to default host (try --help)"
      $apci_rest_test_host = nil
    else
      host_user = ARGV.shift.split('@')
      $apci_rest_test_user = host_user.shift if host_user.length > 1
      $apci_rest_test_host = host_user[0]
      puts 'Connecting to ' + $apci_rest_test_host
    end

  end

  def setup
    if $login_response.nil?
      if $apci_rest_test_user.nil? || $apci_rest_test_pass.nil?
        get_args
      end

      if $apci_session.nil?
        $apci_session = ApcirClient.new(nil, $apci_rest_test_host)
      end

      # End arguments

      # TODO - Log only with argument (-l)?
      # Make a folder for some logs!
      path = Dir.pwd + '/test_logs'
      begin
        FileUtils.mkdir(path)
      rescue
        # Do nothing, it's already there?  Perhaps catch a more specific error?
      ensure
        logger = Logger.new(path + '/test.log', 'daily')
        logger.level = Logger::DEBUG
        logger.info('initialize') { "Initializing..." }
        $apci_session.log(logger)
      end

      # Account shouldn't be hard coded!
      $login_response = $apci_session.login($apci_rest_test_user, $apci_rest_test_pass)
    end
    $apci_session = $apci_session
  end

  def teardown
    #$apci_session.logout
  end

  def test_user_get
    # user 1 should always exist, but you might not have permission...
    uid = 1
    user = $apci_session.user_get(uid)
    assert_equal(uid.to_s, user['uid'])
  end

  def test_user_list
    user = $apci_session.user_list({:mail => 'admin@allplayers.com'})
    assert_equal("1", user['item'].first['uid'])
  end

  def test_user_create
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    birthday = Date.new(1983,5,23)
    response = $apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      birthday
    )
    # Check user create response.
    assert_not_nil(response['uid'])
    # Get the newly created user.
    user = $apci_session.user_get(response['uid'])
    # Check email.
    assert_equal(random_first + '@example.com', user['mail'])
    # Check name.
    assert_equal(random_first, user['field_firstname'])
    assert_equal('FakeLast', user['field_lastname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check gender (1 = Male, 2 = Female) <= Lame
    assert_equal('1', user['field_user_gender'])
  end

  def test_user_create_full
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    birthday = Date.new(1983,5,23)
    more_params = {
      'field_hat_size' => {'0' => {'value' => 'Youth - S'}},
      'field_pant_size' => {'0' => {'value' => 'Youth - L'}},
      'field_size' => {'0' => {'value' => apci_field_shirt_size('L')}},
      'field_shoe_size' => {'0' => {'value' => apci_field_shoe_size('Adult - Male - 5.5')}},
      'field_height' => {'0' => {'value' => apci_field_height("6' 3\"")}},
      'field_phone' => {'0' => {'value' => '5555554321'}},
      'field_organization' => {'0' => {'value' => 'Awesome Test Company'}},
      'field_school' => {'0' => {'value' => 'The REST School'}},
      'field_school_grade' => {'0' => {'value' => '10'}},
      'field_emergency_contact_fname' => {'0' => {'value' => 'Test'}},
      'field_emergency_contact_lname' => {'0' => {'value' => 'Emergency'}},
      'field_emergency_contact_phone' => {'0' => {'value' => '5555551234'}},
      'locations' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      'field_emergency_contact' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      }
    response = $apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      birthday,
      more_params
    )
    # Check user create response.
    assert_not_nil(response['uid'])
    # Get the newly created user.
    user = $apci_session.user_get(response['uid'])

    # Check email.
    assert_equal(random_first + '@example.com', user['mail'])
    # Check name.
    assert_equal(random_first, user['field_firstname'])
    assert_equal('FakeLast', user['field_lastname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check gender (1 = Male, 2 = Female) <= Lame
    assert_equal('1', user['field_user_gender'])

    assert_equal(more_params['field_hat_size']['0']['value'], user['field_hat_size'])
    assert_equal(more_params['field_pant_size']['0']['value'], user['field_pant_size'])
    assert_equal(more_params['field_phone']['0']['value'], user['field_phone'])
    assert_equal(more_params['field_organization']['0']['value'], user['field_organization'])
    assert_equal(more_params['field_school']['0']['value'], user['field_school'])
    assert_equal(more_params['field_school_grade']['0']['value'], user['field_school_grade'])
    assert_equal(more_params['field_emergency_contact_fname']['0']['value'], user['field_emergency_contact_fname'])
    assert_equal(more_params['field_emergency_contact_lname']['0']['value'], user['field_emergency_contact_lname'])
    assert_equal(more_params['field_emergency_contact_phone']['0']['value'], user['field_emergency_contact_phone'])
    # @TODO Really should test profile fields, gender, etc.
  end

  def test_user_profile_update
    uid = 1

    profiles = $apci_session.node_list({
        :uid => uid.to_s,
        :type => 'profile',
      })
    nid = profiles['item'].first['nid']
    profile = $apci_session.node_get(nid)

    birthday = Date.new(1983,5,23)

    params = {
      :field_birth_date => {:'0' => {:value => {
            :month => birthday.mon.to_s(),
            :hour => '0',
            :minute => '0',
            :second => '0',
            :day => birthday.mday.to_s(),
            :year => birthday.year.to_s(),
          }}},
      'field_school' => {'0' => {'value' => 'Ruby School'}},
      'field_firstname[0][value]'=> 'Tested',
      'field_lastname[0][value]'=> 'Admin',
      'group-emergency-contact' => {
        'field_emergency_contact_fname' => {'0' => {'value' => 'Test Emg. Fname'}},
        'field_emergency_contact_lname' => {'0' => {'value' => 'Test Emg. Lname'}},
      },
      'location' => {
        'street' => {'0' => {'value' => '123 Street Dr.'}},
        'additional' => {'0' => {'value' => 'Suite 2'}},
        'city' => {'0' => {'value' => 'Lewisville'}},
        'province' => {'0' => {'value' => '123 Street Dr.'}},
        'postal_code' => {'0' => {'value' => '75067'}},
        'country' => {'0' => {'value' => 'us'}},
      },
    }
    response = $apci_session.node_update(nid, params)

    #puts response.to_yaml
    updated_profile = $apci_session.node_get(nid)
    return

    random_first = (0...8).map{65.+(rand(25)).chr}.join

  end

  def test_user_create_child
    parent_1_uid = 10995
    # TODO - Make someone the parent.
    # TODO - Allplayers.net email.
    more_params = {
      #'email_alternative' => {'value' => '1'}, # Allplayers.net email
      }
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    # Make an 11 year old.
    birthday = Date.today - (365 * 11)
    response = $apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      birthday,
      more_params
    )
    assert_not_nil(response['uid'])

    #Assign parent.
    parenting_response = $apci_session.user_parent_add(response['uid'], parent_1_uid)
    user = $apci_session.user_get(response['uid'])
    # Check firstname.
    assert_equal(random_first, user['field_firstname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check parent.
    parent = $apci_session.user_get(parent_1_uid)
    assert(user['field_parents'].to_s.include? parent['realname'])
    # @TODO Really should test birthdate, gender, etc.
  end

  def test_user_create_child_allplayers_dot_net
    # @TODO - Create the parent, this is glenn...
    parent_1_uid = 10995
    more_params = {
      :email_alternative => {:value => 1}, # Allplayers.net email
      }
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    # Make an 11 year old.
    birthday = Date.today - (365 * 11)
    response = $apci_session.user_create(
      nil, # No email address
      random_first,
      'FakeLast',
      'Male',
      birthday,
      more_params
    )
    assert_not_nil(response['uid'])

    #Assign parent.
    parenting_response = $apci_session.user_parent_add(response['uid'], parent_1_uid)
    user = $apci_session.user_get(response['uid'])
    # Check firstname.
    assert_equal(random_first, user['field_firstname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check parent.
    parent = $apci_session.user_get(parent_1_uid)
    assert(user['field_parents'].to_s.include? parent['realname'])
    # @TODO Really should test birthdate, gender, etc.
  end

  def test_node_get
    # node id 6 should exist, fragile...
    node = $apci_session.node_get(6)
    assert_equal("6", node['nid'])
  end

  def test_node_create
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    body = 'This is a test node generated by test_apci_rest.rb'
    response = $apci_session.node_create(
      random_title,
      'book',
      body
    )
    assert_not_nil(response['nid'])
    node = $apci_session.node_get(response['nid'])
    assert_equal(random_title, node['title'])
    assert_equal('book', node['type'])
    assert_equal(body, node['body'])
  end

  def test_node_update
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    body = 'This is a test node generated by test_apci_rest.rb.'
    response = $apci_session.node_create(
      random_title,
      'book',
      body
    )
    node = $apci_session.node_get(response['nid'])

    body = body + ' Testing update, blah, blah, blah.'
    more_params = { :body => body }
    update_response = $apci_session.node_update(response['nid'], more_params)
    assert_equal(node['nid'], update_response.first)
    updated_node = $apci_session.node_get(response['nid'])
    assert_equal(node['nid'], updated_node['nid'])
    assert_equal(random_title, updated_node['title'])
    assert_equal(body, updated_node['body'])
    assert_equal('book',updated_node['type'])
  end

  def test_node_list
    nid = 6
    nodes = $apci_session.node_list({:nid => nid.to_s})
    assert_equal(nid.to_s, nodes['item'].first['nid'])
  end

  def test_group_create
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    more_params = {}
    location = {
      :street => '122 Main ',
      :additional => 'Suite 303',
      :city => 'Lewisville',
      :province => 'TX',  # <-- Test Breaker!
      :postal_code => '75067',
      :country => 'us',
    }

    response = $apci_session.group_create(
     random_title,
     'This is a test group generated by test_apci_rest.rb',
     location,
     ['Sports', 'Baseball'],
     'Other',
     more_params
    )
    assert_not_nil(response['nid'])
    group = $apci_session.node_get(response['nid'])
    assert_equal(random_title, group['title'])
    assert_equal('group', group['type'])
    assert_equal('Sports', group['taxonomy']['item'].first['name'])
  end

  def test_group_roles_list
    # node id 116518, dev badminton....
    nid = 116518 # Group ID to test.
    uid = 10055 # Chris Chris...
    roles = $apci_session.group_roles_list(nid)
    assert_equal(nid.to_s, roles['item'].first['nid'])
    # Test with a user filter.
    roles = $apci_session.group_roles_list(nid,uid)
    # TODO - Crappy test
    assert_not_nil(roles['item'].first)
  end

  def test_group_users_list
    # node id 116518, dev badminton....
    nid = 116518 # Group ID to test.
    users = $apci_session.group_users_list(nid)
    assert_equal(nid.to_s, users['item'].first['nid'])
    assert_not_nil(users['item'].first['uid'])
  end

  def test_user_join_group
    begin
      # node id 116518, dev badminton....
      nid = 116518 # Group ID to test.
      uid = 9735 # Kat...
      $apci_session.user_join_group(uid, nid)
      users = $apci_session.group_users_list(nid)

      users_uids = []
      users['item'].each do | user |
        users_uids.push(user['uid'])
      end

      assert(users_uids.include?(uid.to_s))
    ensure
      # Remove the user.
      $apci_session.user_leave_group(uid, nid)
    end
  end

#  def test_user_leave_group
#    begin
#      # node id 116518, dev badminton....
#      nid = 116518 # Group ID to test.
#      uid = 12605 # Corey...
#      $apci_session.user_leave_group(uid, nid)
#      users = $apci_session.group_users_list(nid)
#
#      users_uids = []
#      puts users.to_yaml
#      users['item'].each do | user |
#        users_uids.push(user['uid'])
#      end
#
#      assert(!users_uids.include?(uid.to_s))
#    ensure
#      # Put the user back.
#      # TODO - You just bork'd the roles, need to save them and put them back!
#      $apci_session.user_join_group(uid, nid)
#    end
#  end

  def test_user_groups_list
    uid = 1 # User ID to test.
    groups = $apci_session.user_groups_list(uid)
    assert_equal(uid.to_s, groups['item'].first['uid'])
    assert_not_nil(groups['item'].first['nid'])
  end

  def test_user_group_role_add
    begin
      # node id 116518, dev badminton....
      group_nid = 116518
      uid = 10995 # Glenn Pratt
      role_name = 'Volunteer'

      # Get a rid to assign.
      rid = nil
      roles = $apci_session.group_roles_list(group_nid)

      roles['item'].each do | role |
        if role['name'] == role_name
          rid = role['rid']
        end
      end

      response = $apci_session.user_group_role_add(uid, group_nid, rid) unless rid.nil?

      # Test with a user filter.
      user_roles = $apci_session.group_roles_list(group_nid, uid)

      user_role_names = []
      user_roles['item'].each do | user_role |
        user_role_names.push(user_role['name'])
      end

      assert(['1', 'role already granted'].include?(response))
      assert(user_role_names.include?(role_name))
    ensure
      # TODO - Remove the role.  Not implemented in API.
    end
  end

  def test_taxonomy_vocabulary_list
    vocab = $apci_session.taxonomy_vocabulary_list({:module => 'features_group_category'})
    assert_equal("features_group_category", vocab['item'].first['module'])
  end

  def test_taxonomy_term_list
    term = $apci_session.taxonomy_term_list({:name => 'Other'})
    assert_equal("Other", term['item'].first['name'])
  end

  #def test_login
    #if $login_response
    #  response = $login_response
    #else
    #  response = $apci_session.login($apci_rest_test_user, $apci_rest_test_pass)
    #  $apci_session.logout
    #  setup()
    #end
    #assert_not_nil(response['user']['uid'])
    #assert_not_nil(response['sessid'])
  #end

  #def test_logout
    #response = $apci_session.logout
    #assert_equal("1", response)
    #assert_nil(response['sessid'])
    # Should verify we are actually logged out here, can't post, no cookies, etc...
    #setup()
  #end
end
