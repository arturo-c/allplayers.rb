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
        'Male',
        $birthday
      )
    end

    it "should be created properly." do
      # Check user get response.
      user = $apci_session.user_get($user['uid'])
      # Check mail.
      user['mail'].should == $random_first + '@example.com'
      # Check username.
      user['apci_user_username'].should == $random_first + ' FakeLast'
      # Check profile fields.
      profile = $apci_session.user_get_profile($user['uid'])
      # Check name.
      profile['field_firstname']['item'].first['value'].should == $random_first
      profile['field_lastname']['item'].first['value'].should == 'FakeLast'
      # Check birthday.
      Date.parse(profile['field_birth_date']['item'].first['value']).to_s.should == $birthday.to_s
      # Check gender (1 = Male, 2 = Female) <= Lame
      profile['field_user_gender']['item'].first['value'].should == "1"
    end

    it "should be created properly. (full user with profile fields)" do
      random_first = (0...8).map{65.+(rand(25)).chr}.join
      birthday = Date.new(1983,5,23)
      more_params = {
        'field_hat_size' => {'0' => {'value' => 'Youth - S'}},
        'field_pant_size' => {'0' => {'value' => 'Youth - L'}},
        'field_size' => {'0' => {'value' => apci_field_shirt_size('L')}},
        'field_shoe_size' => {'0' => {'value' => apci_field_shoe_size('Adult - Male - 5.5')}},
        'field_height' => {'0' => {'value' => apci_field_height("6' 3\"")}},
        'field_phone' => {'0' => {'value' => '5555554321'}},
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
      response['uid'].should_not == nil
      # Get the newly created user.
      user = $apci_session.user_get(response['uid'])
      # Check email.
      user['mail'].should == random_first + '@example.com'
      # Check calculated username.
      user['apci_user_username'].should == random_first + ' FakeLast'

      # Check profile fields.
      profile = $apci_session.user_get_profile(response['uid'])
      # Check name.
      profile['field_firstname']['item'].first['value'].should == random_first
      profile['field_lastname']['item'].first['value'].should == 'FakeLast'
      # Check birthday.
      Date.parse(profile['field_birth_date']['item'].first['value']).to_s.should == birthday.to_s
      # Check gender (1 = Male, 2 = Female) <= Lame
      profile['field_user_gender']['item'].first['value'].should == '1'

      profile['field_hat_size']['item'].first['value'].should == more_params['field_hat_size']['0']['value']
      profile['field_pant_size']['item'].first['value'].should == more_params['field_pant_size']['0']['value']
      profile['field_phone']['item'].first['value'].should == more_params['field_phone']['0']['value']
      profile['field_school']['item'].first['value'].should == more_params['field_school']['0']['value']
      profile['field_school_grade']['item'].first['value'].should == more_params['field_school_grade']['0']['value']
      profile['field_emergency_contact_fname']['item'].first['value'].should == more_params['field_emergency_contact_fname']['0']['value']
      profile['field_emergency_contact_lname']['item'].first['value'].should == more_params['field_emergency_contact_lname']['0']['value']
      profile['field_emergency_contact_phone']['item'].first['value'].should == more_params['field_emergency_contact_phone']['0']['value']
    end

    it "should be able to update." do
      uid = $user['uid']

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
        :type => 'profile'
      }
      response = $apci_session.node_update(nid, params)

      #puts response.to_yaml
      updated_profile = $apci_session.node_get(nid)
    end

    it "should be retrievable. (get)" do
      uid = $user['uid']
      user = $apci_session.user_get(uid)
      user['uid'].should == uid.to_s
    end

    it "should list users." do
      user = $apci_session.user_list({:mail => $random_first + '@example.com'})
      user['item'].first['uid'].should == $user['uid']
    end

    it "should not create users with same email when multi-threading." do
      pending "until we fix duplicate users on prod."
      for i in 1..4 do
        name = (0...8).map{65.+(rand(25)).chr}.join
        user_create_multiple_threads(name)
      end
    end

    describe "Child" do
      it "should be created properly." do
        user = $apci_session.user_get($user['uid'])
        parent = $apci_session.public_user_get(nil, user['mail'])
        parent_1_uuid = parent['item'].first['uuid']
        random_first = (0...8).map{65.+(rand(25)).chr}.join
        more_params = {
          :email => random_first + '@example.com',
        }
        birthday = '2004-05-21'
        $child = $apci_session.public_children_add(
          parent_1_uuid,
          random_first,
          'FakeLast',
          birthday,
          'm',
          more_params
        )
        $child['uuid'].should_not == nil

        # Get children from parent.
        children = $apci_session.public_user_children_list(parent_1_uuid)
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
        user = $apci_session.user_get($user['uid'])
        parent = $apci_session.public_user_get(nil, user['mail'])
        parent_1_uuid = parent['item'].first['uuid']
        random_first = (0...8).map{65.+(rand(25)).chr}.join
        birthday = '2004-05-21'
        more_params = {}
        $child = $apci_session.public_children_add(
          parent_1_uuid,
          random_first,
          'FakeLast',
          birthday,
          'm',
          more_params
        )
        $child['uuid'].should_not == nil

        # Get children from parent.
        children = $apci_session.public_user_children_list(parent_1_uuid)
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

    protected

    def user_create_multiple_threads(name)
      # Multi-thread
      threads = []
      # Set default thread_count to 7, accept global to change it.
      thread_count = $thread_count.nil? ? 4 : $thread_count
      succeed = 0
      failures = 0
      for i in 1..thread_count do
        threads << Thread.new {
          begin
            birthday = Date.new(1983,5,23)
            response = $apci_session.user_create(
              name + '@example.com',
              name,
              'FakeLast',
              'Male',
              birthday
            )
          rescue => e
            failures += 1
          else
            succeed += 1
          end
        }
      end
      threads.each_index {|i|
        threads[i].join
      }
      succeed.should == 1
      failures.should == thread_count - 1
      users = $apci_session.user_list({:mail => name + '@example.com'})
      users['item'].size.should == 1
    end
  end
end
