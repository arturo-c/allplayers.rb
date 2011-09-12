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
      @base_uri = Addressable::URI.join(protocol + server, '/api/rest/')
      @key = api_key # TODO - Not implemented in API yet.
      @session_cookies = {}
    end
    
    # GET, PUT, POST, DELETE, etc.
    def get(path, query = {}, headers = {})
    # @TODO - cache here (HTTP Headers?)
      begin
        uri = @base_uri.join(path)
        # TODO - Convert all query values to strings.
        uri.query_values = query unless query.empty?
        headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
        RestClient.log = @log
        RestClient.open_timeout = 600
        RestClient.timeout = 600
        response = RestClient.get(uri.to_s, headers)
        # @TODO - Review this logic - Update the cookies.
        @session_cookies.merge!(response.cookies) unless response.cookies.empty?
        # @TODO - There must be a way to change the base object (XML string to
        #   Hash) while keeping the methods...
        XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
      rescue REXML::ParseException => xml_err
        # XML Parser error
        raise "Failed to parse server response."
      end
    end

    def post(path, params = {}, headers = {})
      begin
        uri = @base_uri.join(path)
        headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
        RestClient.log = @log
        RestClient.open_timeout = 600
        RestClient.timeout = 600
        response = RestClient.post(uri.to_s, params, headers)
        # @TODO - Review this logic - Update the cookies.
        @session_cookies.merge!(response.cookies) unless response.cookies.empty?
        # @TODO - There must be a way to change the base object (XML string to
        #   Hash) while keeping the methods...
        XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
      rescue REXML::ParseException => xml_err
        # XML Parser error
        raise "Failed to parse server response."
      end
    end

    def put(path, params = {}, headers = {})
      begin
        uri = @base_uri.join(path)
        headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
        RestClient.log = @log
        RestClient.open_timeout = 600
        RestClient.timeout = 600
        response = RestClient.put(uri.to_s, params, headers)
        # @TODO - Review this logic - Update the cookies.
        @session_cookies.merge!(response.cookies) unless response.cookies.empty?
        # @TODO - There must be a way to change the base object (XML string to
        #   Hash) while keeping the methods...
        XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
      rescue REXML::ParseException => xml_err
        # XML Parser error
        raise "Failed to parse server response."
      end
    end
  end
end
