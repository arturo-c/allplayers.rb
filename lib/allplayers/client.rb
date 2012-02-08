require 'rubygems'
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
    def initialize(api_key = nil, server = 'sandbox.allplayers.com', protocol = 'https://', auth = 'session')
      if (auth == 'session')
        extend AllPlayers::Auth::Session
      end
      @base_uri = Addressable::URI.join(protocol + server, '')
      @key = api_key # TODO - Not implemented in API yet.
      @session_cookies = {}
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
      begin
        if ['albums', 'announcements', 'broadcasts', 'events', 'groups', 'messages', 'photos', 'resources', 'users'].include? path
          uri = Addressable::URI.join(@base_uri, 'api/v1/rest/'+path.to_s)
        else
          uri = Addressable::URI.join(@base_uri, 'api/rest/'+path.to_s)
        end
        uri.query_values = query unless query.empty?
        headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
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
        puts html_response
        # @TODO - Review this logic - Update the cookies.
        @session_cookies.merge!(response.cookies) unless response.cookies.empty?
        # @TODO - There must be a way to change the base object (XML string to
        #   Hash) while keeping the methods...
        XmlSimple.xml_in(xml_response, { 'ForceArray' => ['item'] })
      rescue REXML::ParseException => xml_err
        # XML Parser error
        raise "Failed to parse server response."
      end
    end
  end
end
