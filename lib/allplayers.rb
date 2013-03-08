# Require minimal files needed for AllPlayers public API here.
require 'allplayers/monkey_patches/rest_client'
require 'allplayers/api'
require 'allplayers/client'
require 'allplayers/configuration'

module AllPlayers
  extend Configuration
  class << self
    def new(server = 'https://www.allplayers.com', auth = 'basic', access_token = nil)
      @client = AllPlayers::Client.new(server, auth, access_token)
    end

    def client(server = 'https://www.allplayers.com', auth = 'basic', access_token = nil)
      @client = AllPlayers::Client.new(server, auth, access_token) unless defined?(@client)
      @client
    end
  end
end
