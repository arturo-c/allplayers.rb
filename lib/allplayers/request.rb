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
        uri = Addressable::URI.join(@base_uri, 'api/v1/rest/'+path.to_s+'.json')
        query_params = Rack::Utils.build_nested_query(query)
        string_uri = uri.to_s
        string_uri = string_uri + '?' + query_params
        headers.merge!(@headers) unless @headers.empty?
        if headers[:Content_Type] == 'application/json'
          payload = payload.to_json
        end

        # Use access_token if this is oauth authentication.
        unless @access_token.nil?
          if [:patch, :post, :put].include? verb
            response = @access_token.request(verb, uri.to_s, payload, headers)
          else
            response = @access_token.request(verb, string_uri, headers)
          end
          return JSON.parse(response.body) if response.code == '200'
          return 'No Content' if response.code == '204'
          raise AllPlayers::Error.new(response), 'Oauth Error'
        else
          # Use RestClient if using basic auth.
          if [:patch, :post, :put].include? verb
            response = RestClient.send(verb, uri.to_s, payload, headers)
          else
            response = RestClient.send(verb, string_uri, headers)
          end
          return JSON.parse(response) if response.code == 200
        end
        return 'No Content' if response.code == 204
        raise AllPlayers::Error.new(response), 'RestClient Error'
      end
    end
  end
end
