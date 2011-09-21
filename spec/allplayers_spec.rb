require 'helper'
require 'allplayers/api_spec'
require 'allplayers/start_apci_session'

describe AllPlayers do
  describe ".new" do
    it "should return a Allplayers::Client" do
      AllPlayers.new.should be_a AllPlayers::Client
    end
  end
end
