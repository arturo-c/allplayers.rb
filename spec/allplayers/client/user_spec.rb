require 'helper'

describe AllPlayers::Client do
  before do
    @client = AllPlayers::Client.new
  end
  describe ".user_create" do
    before :each do
      $birthday = Date.new(1983,5,23)
      $random_first = (0...8).map{65.+(rand(25)).chr}.join if $random_first.nil?
      $response = $apci_session.user_create(
        $random_first + '@example.com',
        $random_first,
        'FakeLast',
        'Male',
        $birthday
      )
    end
    it "should be created properly." do
      # Check user get response.
      user = $apci_session.user_get($response['uid'])
      # Check mail.
      user['mail'].should == $random_first + '@example.com'
      # Check username.
      user['apci_user_username'].should == $random_first + ' FakeLast'
      # Check profile fields.
      profile = $apci_session.user_get_profile($response['uid'])
      # Check name.
      profile['field_firstname']['item'].first['value'].should == $random_first
      profile['field_lastname']['item'].first['value'].should == 'FakeLast'
      # Check birthday.
      Date.parse(profile['field_birth_date']['item'].first['value']).to_s.should == $birthday.to_s
      # Check gender (1 = Male, 2 = Female) <= Lame
      profile['field_user_gender']['item'].first['value'].should == "1"
    end
  end
end
