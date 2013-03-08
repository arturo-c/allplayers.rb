require 'allplayers/api'

module AllPlayers
  class Client < API
    require 'rubygems'
    require 'bundler/setup'
    require 'restclient'
    require 'json'
    require 'addressable/uri'
    require 'xmlsimple'
    require 'logger'
    require 'active_support/base64'
    require 'allplayers/client/events'
    require 'allplayers/client/users'
    require 'allplayers/client/groups'
    require 'allplayers/client/forms'
    require 'allplayers/authentication'
    require 'allplayers/error'
    require 'allplayers/rate_limit'
    require 'allplayers/error/decode_error'
    require 'allplayers/error/restclient_error'
    require 'oauth'
    require 'rack'
    include AllPlayers::Events
    include AllPlayers::Users
    include AllPlayers::Groups
    include AllPlayers::Forms
  end
end
