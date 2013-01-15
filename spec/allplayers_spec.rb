require 'helper'
require 'allplayers/start_apci_session'
require 'allplayers/api_spec'
require 'allplayers/client/users_spec'
require 'allplayers/client/groups_spec'
require 'allplayers/client/events_spec'

describe AllPlayers do
  describe "New" do
    it "should return an Allplayers::Client." do
      AllPlayers.new.should be_a AllPlayers::Client
    end
  end
end
