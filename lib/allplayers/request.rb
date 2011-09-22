module AllPlayers
  module Request
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

    private

    # Perform an HTTP request
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
