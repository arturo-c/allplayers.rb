require 'allplayers/request'
require 'allplayers/authentication'
require 'addressable/uri'
require 'restclient'

module AllPlayers
  class API

    include Request
    include Authentication
    attr_accessor :logger

    def initialize(server = 'https://www.allplayers.com', auth = 'basic', access_token = nil)
      @base_uri = server
      if (auth == 'basic')
        extend AllPlayers::Authentication
      end
      @access_token = access_token
      @headers = {}
    end

    # Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
    def prepare_access_token(oauth_token, oauth_token_secret, consumer_token, consumer_secret)
      consumer = OAuth::Consumer.new(consumer_token, consumer_secret, {:site => @base_uri})
      # now create the access token object from passed values
      token_hash = {:oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret}
      @access_token = OAuth::AccessToken.from_hash(consumer, token_hash)
    end

    def log(target)
      @log = target
      RestClient.log = target
    end

    # Add header method, preferably use array of symbols, e.g. {:USER-AGENT => 'RubyClient'}.
    def add_headers(header = {})
      @headers.merge!(header) unless header.nil?
    end

    # Remove headers from a session.
    def remove_headers(headers = {})
      headers.each do |header, value|
        @headers.delete(header)
      end
    end

  end
end
