require 'helper'

describe AllPlayers::Client do
  describe "User Create" do
    before :all do
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

    it "should be retrievable." do
      uid = $user['uid']
      user = $apci_session.user_get(uid)
      user['uid'].should == uid.to_s
    end

    it "should not create users with same email (multi-thread checking)." do
      pending "until we fix duplicate users on prod."
      for i in 1..4 do
        name = (0...8).map{65.+(rand(25)).chr}.join
        user_create_multiple_threads(name)
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
