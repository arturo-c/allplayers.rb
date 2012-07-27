require 'allplayers/api'

module AllPlayers
  class Client < API
    require 'rubygems'
    require 'bundler/setup'
    require 'restclient'
    require 'addressable/uri'
    require 'allplayers/client/node'
    require 'allplayers/client/event'
    require 'allplayers/client/user'
    require 'allplayers/client/group'
    require 'allplayers/client/taxonomy'
    require 'allplayers/client/file'
    include AllPlayers::Event
    include AllPlayers::User
    include AllPlayers::Group
    include AllPlayers::Node
    include AllPlayers::Taxonomy
    include AllPlayers::File
  end
end
