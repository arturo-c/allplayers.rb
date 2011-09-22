require 'helper'
require 'allplayers/api_spec'
require 'allplayers/start_apci_session'
require 'allplayers/client/user_spec'
require 'allplayers/client/node_spec'

describe AllPlayers do
  describe "New" do
    it "should return a Allplayers::Client" do
      AllPlayers.new.should be_a AllPlayers::Client
    end
  end
end
