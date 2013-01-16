require 'addressable/uri'
require 'xmlsimple'
require 'logger'
require 'active_support/base64'
require 'restclient'
require 'allplayers/authentication'
require 'allplayers/request'

module AllPlayers
  class API
    include Request
    include Authentication
    attr_accessor :logger

    def initialize(api_key = nil, server = 'sandbox.allplayers.com', protocol = 'https://', auth = 'session')
      if (auth == 'session')
        extend AllPlayers::Authentication
      end
      @base_uri = Addressable::URI.join(protocol + server, '')
      @key = api_key # TODO - Not implemented in API yet.
      @session_cookies = {}
      @headers = {}
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
