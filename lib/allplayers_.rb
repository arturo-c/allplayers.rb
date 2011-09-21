# Require minimal files needed for AllPlayers public API here.
require 'allplayers/monkey_patches/rest_client'
require 'allplayers/api'
require 'allplayers/client'
require 'allplayers/configuration'

module AllPlayers
  extend Configuration
  class << self
    def new(options={})
      AllPlayers::Client.new(options)
    end
  end
end
