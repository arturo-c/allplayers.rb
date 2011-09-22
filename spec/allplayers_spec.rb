require 'helper'
require 'allplayers/start_apci_session'
require 'allplayers/api_spec'
require 'allplayers/client/user_spec'
require 'allplayers/client/node_spec'
require 'allplayers/client/group_spec'
require 'allplayers/client/taxonomy_spec'
require 'allplayers/client/file_spec'
require 'allplayers/client/event_spec'

describe AllPlayers do
  describe "New" do
    it "should return an Allplayers::Client." do
      AllPlayers.new.should be_a AllPlayers::Client
    end
  end
end
