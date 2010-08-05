#!/usr/bin/ruby

# == TODO RDoc usage help... getoptions...
#
# hello: greets user, demonstrates command line parsing
#
# == Usage
#
# hello [OPTION] ... DIR
#
# -h, --help:
#    show help
#
# --repeat x, -n x:
#    repeat x times
#
# --name [name]:
#    greet user by name, if name not supplied default is John
#
# DIR: The directory in which to issue the greeting.

require 'apci_rest'
require 'test/unit'
require 'getoptlong'
require 'rdoc/usage'
require 'logger'

class TestApcirClient < Test::Unit::TestCase

  def setup
    # Accept host from command line argument. Arguments after -- are sent to the
    # test and not consumed by the test runner.
    # ruby test_apci_rest -v -- www.allplayers.com
    # -v (verbose) is consumed by unit test, www.allplayers.com by this test.
    if (ARGV[0])
      @apci_session = ApcirClient.new(nil, ARGV[0])
    else
      @apci_session = ApcirClient.new
    end
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
      @apci_session.log(logger)
    end

    # Account shouldn't be hard coded!
    @login_response = @apci_session.login('user', '')
  end

  def teardown
    @apci_session.logout
  end

  def test_user_get
    # user 1 should always exist, but you might not have permission...
    uid = 1
    user = @apci_session.user_get(uid)
    assert_equal(uid.to_s, user['uid'])
  end

  def test_user_list
    user = @apci_session.user_list({:mail => 'user@allplayers.com'})
    assert_equal("1", user['item'].first['uid'])
  end

  def test_user_create
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    birthday = Date.new(1983,5,23)
    response = @apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      birthday
    )
    # Check user create response.
    assert_not_nil(response['uid'])
    # Get the newly created user.
    user = @apci_session.user_get(response['uid'])
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
      'field_phone' => {'0' => {'value' => '5555554321'}},
      'field_organization' => {'0' => {'value' => 'Awesome Test Company'}},
      'field_school' => {'0' => {'value' => 'The REST School'}},
      'field_school_grade' => {'0' => {'value' => '10'}},
      'field_emergency_contact_fname' => {'0' => {'value' => 'Test'}},
      'field_emergency_contact_lname' => {'0' => {'value' => 'Emergency'}},
      'field_emergency_contact_phone' => {'0' => {'value' => '555-555-1234'}},
      'locations' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          #'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      'field_emergency_contact' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          #'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      }
    response = @apci_session.user_create(
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
    user = @apci_session.user_get(response['uid'])

    puts user.to_yaml
    # Check email.
    assert_equal(random_first + '@example.com', user['mail'])
    # Check name.
    assert_equal(random_first, user['field_firstname'])
    assert_equal('FakeLast', user['field_lastname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check gender (1 = Male, 2 = Female) <= Lame
    assert_equal('1', user['field_user_gender'])

    assert_equal(more_params['field_hat_size']['0']['value'], user['field_hat_size']['item'].first['value'])
    assert_equal(more_params['field_pant_size']['0']['value'], user['field_pant_size']['item'].first['value'])
    assert_equal(more_params['field_phone']['0']['value'], user['field_phone'])
    assert_equal(more_params['field_organization']['0']['value'], user['field_organization'])
    assert_equal(more_params['field_school']['0']['value'], user['field_school']['item'].first['value'])
    assert_equal(more_params['field_school_grade']['0']['value'], user['field_school_grade']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_fname']['0']['value'], user['field_emergency_contact_fname']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_lname']['0']['value'], user['field_emergency_contact_lname']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_phone']['0']['value'], user['field_emergency_contact_phone']['item'].first['value'])
    # @TODO Really should test profile fields, gender, etc.
  end

  def test_user_profile_update
    uid = 1

    profiles = @apci_session.node_list({
        :uid => uid.to_s,
        :type => 'profile',
      })
    profile = @apci_session.node_get(profiles['item'].first['nid'])
    puts profile.to_yaml
    return

    random_first = (0...8).map{65.+(rand(25)).chr}.join
    birthday = Date.new(1983,5,23)
    more_params = {
      'field_hat_size' => {'0' => {'value' => 'Youth - S'}},
      'field_pant_size' => {'0' => {'value' => 'Youth - L'}},
      'field_phone' => {'0' => {'value' => '5555554321'}},
      'field_organization' => {'0' => {'value' => 'Awesome Test Company'}},
      'field_school' => {'0' => {'value' => 'The REST School'}},
      'field_school_grade' => {'0' => {'value' => '10'}},
      'field_emergency_contact_fname' => {'0' => {'value' => 'Test'}},
      'field_emergency_contact_lname' => {'0' => {'value' => 'Emergency'}},
      'field_emergency_contact_phone' => {'0' => {'value' => '555-555-1234'}},
      'locations' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          #'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      'field_emergency_contact' => {'0' => {
          'street' => '1514 Glencairn Ln.',
          'additional' => 'Suite 2',
          'city' => 'Lewisville',
          #'province' => 'TX',
          'postal_code' => '75067',
          'country' => 'us',
          }
        },
      }
    response = @apci_session.user_create(
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
    user = @apci_session.user_get(response['uid'])

    profiles = @apci_session.node_list({:uid => response['uid']})
    puts profiles.to_yaml

    puts user.to_yaml
    # Check email.
    assert_equal(random_first + '@example.com', user['mail'])
    # Check name.
    assert_equal(random_first, user['field_firstname'])
    assert_equal('FakeLast', user['field_lastname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check gender (1 = Male, 2 = Female) <= Lame
    assert_equal('1', user['field_user_gender'])

    assert_equal(more_params['field_hat_size']['0']['value'], user['field_hat_size']['item'].first['value'])
    assert_equal(more_params['field_pant_size']['0']['value'], user['field_pant_size']['item'].first['value'])
    assert_equal(more_params['field_phone']['0']['value'], user['field_phone'])
    assert_equal(more_params['field_organization']['0']['value'], user['field_organization'])
    assert_equal(more_params['field_school']['0']['value'], user['field_school']['item'].first['value'])
    assert_equal(more_params['field_school_grade']['0']['value'], user['field_school_grade']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_fname']['0']['value'], user['field_emergency_contact_fname']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_lname']['0']['value'], user['field_emergency_contact_lname']['item'].first['value'])
    assert_equal(more_params['field_emergency_contact_phone']['0']['value'], user['field_emergency_contact_phone']['item'].first['value'])
    # @TODO Really should test profile fields, gender, etc.
  end

  def test_user_create_child
    parent_1_uid = 10995
    # TODO - Make someone the parent.
    # TODO - Allplayers.net email.
    more_params = {
      :field_parents => {:'0' => {:value => parent_1_uid.to_s}},
      #'email_alternative' => {'value' => '1'}, # Allplayers.net email
      }
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    # Make an 11 year old.
    birthday = Date.today - (365 * 11)
    response = @apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      birthday,
      more_params
    )
    assert_not_nil(response['uid'])

    #Assign parent.
    parenting_response = @apci_session.user_parent_add(response['uid'], parent_1_uid)
    user = @apci_session.user_get(response['uid'])
    # Check firstname.
    assert_equal(random_first, user['field_firstname'])
    # Check birthday.
    assert_equal(birthday.to_s, Date.parse(user['field_birth_date']).to_s)
    # Check parent.
    parent = @apci_session.user_get(parent_1_uid)
    assert(user['field_parents'].include? parent['realname'])
    # @TODO Really should test birthdate, gender, etc.
  end

  def test_node_get
    # node id 6 should exist, fragile...
    node = @apci_session.node_get(6)
    assert_equal("6", node['nid'])
  end

  def test_node_create
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    response = @apci_session.node_create(
      random_title,
      'book',
      'This is a test node generated by test_apci_rest.rb'
    )
    assert_not_nil(response['nid'])
    node = @apci_session.node_get(response['nid'])
    assert_equal(random_title, node['title'])
    assert_equal('book', node['type'])
  end

  def test_node_list
    nid = 6
    nodes = @apci_session.node_list({:nid => nid.to_s})
    assert_equal(nid.to_s, nodes['item'].first['nid'])
  end

  def test_group_create
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    more_params = {}
    location = {
      :street => '122 Main ',
      :additional => 'Suite 303',
      :city => 'Lewisville',
      #:province => 'TX',  # <-- Test Breaker!
      :postal_code => '75067',
    }

    response = @apci_session.group_create(
     random_title,
     'This is a test group generated by test_apci_rest.rb',
     location,
     ['Sports', 'Baseball'],
     'Other',
     more_params
    )
    assert_not_nil(response['nid'])
    group = @apci_session.node_get(response['nid'])
    assert_equal(random_title, group['title'])
    assert_equal('group', group['type'])
    assert_equal('Sports', group['taxonomy']['item'].first['name'])
  end

  def test_group_roles_list
    # node id 116518, dev badminton....
    nid = 116518 # Group ID to test.
    uid = 10055 # Chris Chris...
    roles = @apci_session.group_roles_list(nid)
    assert_equal(nid.to_s, roles['item'].first['nid'])
    # Test with a user filter.
    roles = @apci_session.group_roles_list(nid,uid)
    # TODO - Crappy test
    assert_not_nil(roles['item'].first)
  end

  def test_group_users_list
    # node id 116518, dev badminton....
    nid = 116518 # Group ID to test.
    users = @apci_session.group_users_list(nid)
    assert_equal(nid.to_s, users['item'].first['nid'])
    assert_not_nil(users['item'].first['uid'])
  end

  def test_user_join_group
    begin
      # node id 116518, dev badminton....
      nid = 116518 # Group ID to test.
      uid = 9735 # Kat...
      @apci_session.user_join_group(uid, nid)
      users = @apci_session.group_users_list(nid)

      users_uids = []
      users['item'].each do | user |
        users_uids.push(user['uid'])
      end

      assert(users_uids.include?(uid.to_s))
    ensure
      # Remove the user.
      @apci_session.user_leave_group(uid, nid)
    end
  end

  def test_user_leave_group
    begin
      # node id 116518, dev badminton....
      nid = 116518 # Group ID to test.
      uid = 12605 # Corey...
      @apci_session.user_leave_group(uid, nid)
      users = @apci_session.group_users_list(nid)


      users_uids = []
      users['item'].each do | user |
        users_uids.push(user['uid'])
      end

      assert(!users_uids.include?(uid.to_s))
    ensure
      # Put the user back.
      # TODO - You just bork'd the roles, need to save them and put them back!
      @apci_session.user_join_group(uid, nid)
    end
  end

  def test_user_groups_list
    uid = 1 # User ID to test.
    groups = @apci_session.user_groups_list(uid)
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
      roles = @apci_session.group_roles_list(group_nid)

      roles['item'].each do | role |
        if role['name'] == role_name
          rid = role['rid']
        end
      end

      response = @apci_session.user_group_role_add(uid, group_nid, rid) unless rid.nil?

      # Test with a user filter.
      user_roles = @apci_session.group_roles_list(group_nid, uid)

      user_role_names = []
      user_roles['item'].each do | user_role |
        user_role_names.push(user_role['content'])
      end

      assert(['1', 'role already granted'].include?(response))
      assert(user_role_names.include?(role_name))
    ensure
      # TODO - Remove the role.  Not implemented in API.
    end
  end

  def test_taxonomy_vocabulary_list
    vocab = @apci_session.taxonomy_vocabulary_list({:module => 'features_group_category'})
    assert_equal("features_group_category", vocab['item'].first['module'])
  end

  def test_taxonomy_term_list
    term = @apci_session.taxonomy_term_list({:name => 'Other'})
    assert_equal("Other", term['item'].first['name'])
  end

  def test_login
    if @login_response
      response = @login_response
    else
      response = @apci_session.login('user', '')
      @apci_session.logout
      setup()
    end
    assert_not_nil(response['user']['uid'])
    assert_not_nil(response['sessid'])
  end

  def test_logout
    response = @apci_session.logout
    assert_equal("1", response)
    assert_nil(response['sessid'])
    # Should verify we are actually logged out here, can't post, no cookies, etc...
    setup()
  end
end
