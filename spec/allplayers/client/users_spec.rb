require 'helper'

describe AllPlayers::Client do
  describe "User" do
    before :all do
      # Create User.
      $birthday = Date.new(1983,5,23)
      $random_first = (0...8).map{65.+(rand(25)).chr}.join
      $user = $apci_session.user_create(
        $random_first + '@example.com',
        $random_first,
        'FakeLast',
        $birthday,
        'Male'
      )
    end

    it "should be created properly." do
      # Check user get response.
      user = $apci_session.user_get($user['uuid'])
      # Check mail.
      user['email'].should == $random_first + '@example.com'
      # Check username.
      user['username'].should == $random_first + ' FakeLast'
    end

    describe "Child" do
      it "should be created properly." do
        random_first = (0...8).map{65.+(rand(25)).chr}.join
        more_params = {
          :email => random_first + '@example.com',
        }
        birthday = Date.new(2004,5,23)
        $child = $apci_session.user_create_child(
          $user['uuid'],
          random_first,
          'FakeLast',
          birthday,
          'm',
          more_params
        )
        $child['uuid'].should_not == nil

        # Get children from parent.
        children = $apci_session.user_children_list($user['uuid'])
        child_uuid = children['item'].first['uuid']

        # Verify parent child relationship.
        child_uuid.should == $child['uuid']

        # Check email.
        $child['email'].should == random_first + '@example.com'

        # Check calculated username is only first.
        $child['nickname'].should == random_first

        # Check name.
        $child['firstname'].should == random_first
        $child['lastname'].should == 'FakeLast'

        # Check gender.
        $child['gender'].should == 'male'
      end

      it "should be created properly using an AllPlayers.net email." do
        random_first = (0...8).map{65.+(rand(25)).chr}.join
        birthday = '2004-05-21'
        more_params = {}
        $child = $apci_session.user_create_child(
          $user['uuid'],
          random_first,
          'FakeLast',
          birthday,
          'm',
          more_params
        )
        $child['uuid'].should_not == nil

        # Get children from parent.
        children = $apci_session.user_children_list($user['uuid'])
        child_uuid = children['item'].last['uuid']

        # Verify parent child relationship.
        child_uuid.should == $child['uuid']

        # Check email.
        $child['email'].should == random_first + 'FakeLast@allplayers.net'

        # Check calculated username is only first.
        $child['nickname'].should == random_first

        # Check name.
        $child['firstname'].should == random_first
        $child['lastname'].should == 'FakeLast'

        # Check gender.
        $child['gender'].should == 'male'
      end
    end
  end
end