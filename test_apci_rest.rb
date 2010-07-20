#!/usr/bin/ruby
require 'apci_rest'
require 'test/unit'

class TestApcirClient < Test::Unit::TestCase

  def setup
    @apci_session = ApcirClient.new(nil, 'vbox.allplayers.com')
    @login_response = @apci_session.login('user', '')
  end

  def teardown
    @apci_session.logout
  end

  def test_user_get
    # user 1 should always exist, but you might not have permission...
    user = @apci_session.user_get(1)
    assert_equal("1", user['uid'])
  end

  def test_user_list
    user = @apci_session.user_list({:mail => 'admin@allplayers.com'})
    assert_equal("1", user['item']['uid'])
  end

  def test_user_create
    random_first = (0...8).map{65.+(rand(25)).chr}.join
    response = @apci_session.user_create(
      random_first + '@example.com',
      random_first,
      'FakeLast',
      'Male',
      Date.new(1983,5,23)
    )
    assert_not_nil(response['uid'])
    user = @apci_session.user_get(response['uid'])
    assert_equal(random_first, user['field_firstname'])
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
    user = @apci_session.node_list({:nid => '6'})
    assert_equal("6", user['item']['nid'])
  end

  def test_group_create
    random_title = (0...8).map{65.+(rand(25)).chr}.join
    location = {:postal_code => '75067'}
    response = @apci_session.group_create(
      random_title,
     'This is a test group generated by test_apci_rest.rb',
     location,
     ['Sports', 'Other'],
     'Team'
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
    assert_equal(nid.to_s, roles['item'][0]['nid'])
    # Test with a user filter.
    roles = @apci_session.group_roles_list(nid,uid)
    # TODO - Crappy test
    assert_not_nil(roles['item'][0])
  end

  def test_group_users_list
    # node id 116518, dev badminton....
    nid = 116518 # Group ID to test.
    users = @apci_session.group_users_list(nid)
    assert_equal(nid.to_s, users['item'][0]['nid'])
    assert_not_nil(users['item'][0]['uid'])
  end

  def test_user_join_group
    begin
      # node id 116518, dev badminton....
      nid = 116518 # Group ID to test.
      uid = 9735 # Kat...
      response = @apci_session.user_join_group(uid, nid)
      puts response.to_yaml
      users = @apci_session.group_users_list(nid)
      puts users.to_yaml
      assert_equal(nid.to_s, users['item'][0]['nid'])
      assert_not_nil(users['item'][0]['uid'])
    ensure
      # Try to cleanup.
      response = @apci_session.user_leave_group(uid, nid)
      puts response.to_yaml
    end
  end

  def test_user_leave_group
    begin
      # node id 116518, dev badminton....
      nid = 116518 # Group ID to test.
      uid = 10055 # Chris Chris...
      response = @apci_session.user_leave_group(uid, nid)
      puts response.to_yaml
      users = @apci_session.group_users_list(nid)
      puts users.to_yaml
      assert_equal(nid.to_s, users['item'][0]['nid'])
      assert_not_nil(users['item'][0]['uid'])
    ensure
      # Try to cleanup.
      response = @apci_session.user_join_group(uid, nid)
      puts response.to_yaml
    end
  end

  def test_user_groups_list
    uid = 1 # User ID to test.
    groups = @apci_session.user_groups_list(uid)
    assert_equal(uid.to_s, groups['item'][0]['uid'])
    assert_not_nil(groups['item'][0]['nid'])
  end

  def test_user_group_role_add
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

    puts 'rid = ' + rid

    response = @apci_session.user_group_role_add(uid, group_nid, rid) unless rid.nil?
    puts response.to_yaml
    
    # Test with a user filter.
    user_roles = @apci_session.group_roles_list(group_nid, uid)
    
    user_role_names = []
    user_roles['item'].each do | user_role |
      user_role_names.push(user_role['content'])
    end

    assert(['1', 'role already granted'].include?(response))
    assert(user_role_names.include?(role_name))
  end

  def test_taxonomy_vocabulary_list
    vocab = @apci_session.taxonomy_vocabulary_list({:module => 'features_group_category'})
    assert_equal("features_group_category", vocab['item']['module'])
  end

  def test_taxonomy_term_list
    term = @apci_session.taxonomy_term_list({:name => 'Other'})
    assert_equal("Other", term['item'][0]['name'])
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
