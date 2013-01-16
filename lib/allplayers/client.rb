require 'allplayers/api'

module AllPlayers
  class Client < API
    require 'rubygems'
    require 'bundler/setup'
    require 'restclient'
    require 'addressable/uri'
    require 'allplayers/client/events'
    require 'allplayers/client/users'
    require 'allplayers/client/groups'
    include AllPlayers::Events
    include AllPlayers::Users
    include AllPlayers::Groups
  end
end
