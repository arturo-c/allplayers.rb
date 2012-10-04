require 'rubygems'
require 'bundler/setup'
require 'restclient'
require 'addressable/uri'
require 'allplayers/auth/session'
require 'allplayers/events'
require 'allplayers/users'
require 'allplayers/groups'

# Basic REST Operations.
module AllPlayers
  class Client
    include AllPlayers::Events
    include AllPlayers::Users
    include AllPlayers::Groups
    def initialize(api_key = nil, server = 'sandbox.allplayers.com', protocol = 'https://', auth = 'session', access_token = nil)
      if (auth == 'session')
        extend AllPlayers::Auth::Session
      end
      if (auth == 'oauth')
        RestClient.add_before_execution_proc do |req, params|
          access_token.sign! req
        end
      end
      @base_uri = Addressable::URI.join(protocol + server, '')
      @key = api_key # TODO - Not implemented in API yet.
      @headers = {}
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

    # GET, PUT, POST, DELETE, etc.
    def get(path, query = {}, headers = {})
      # @TODO - cache here (HTTP Headers?)
      request(:get, path, query, {}, headers)
    end

    def post(path, payload = {}, headers = {})
      request(:post, path, {}, payload, headers)
    end

    def put(path, payload = {}, headers = {})
      request(:put, path, {}, payload, headers)
    end

    def delete(path, headers = {})
      request(:delete, path, {}, {}, headers)
    end

    def request(verb, path, query = {}, payload = {}, headers = {})
      if path.to_s =~ /albums|announcements|broadcasts|events|groups|messages|photos|resources|users/i
        uri = Addressable::URI.join(@base_uri, 'api/v1/rest/'+path.to_s)
      else
        uri = Addressable::URI.join(@base_uri, 'api/rest/'+path.to_s)
      end
      uri.query_values = query unless query.empty?
      headers.merge!(@headers) unless @headers.empty?
      if @access_token.nil?
        begin
          RestClient.log = @log
          RestClient.open_timeout = 600
          RestClient.timeout = 600
          if [:patch, :post, :put].include? verb
            response = RestClient.send(verb, uri.to_s, payload, headers)
          else
            response = RestClient.send(verb, uri.to_s, headers)
          end
          xml_response =  '<?xml' + response.split("<?xml").last
          html_response = response.split("<?xml").first
          puts html_response if !html_response.empty?
          # @TODO - There must be a way to change the base object (XML string to
          #   Hash) while keeping the methods...
          XmlSimple.xml_in(xml_response, { 'ForceArray' => ['item'] })
        rescue REXML::ParseException => xml_err
          # XML Parser error
          raise "Failed to parse server response."
        end
      else
        if [:patch, :post, :put].include? verb
          response = @access_token.request(verb, uri.to_s, payload, headers)
        else
          response = @access_token.request(verb, uri.to_s, headers)
        end
        ActiveSupport::JSON.decode(response.body)
      end
    end
  end
end
