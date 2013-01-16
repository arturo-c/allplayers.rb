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
        uri = Addressable::URI.join(@base_uri, 'api/v1/rest/'+path.to_s)
        uri.query_values = query unless query.empty?
        headers.merge!(@headers) unless @headers.empty?
        RestClient.log = @log
        RestClient.open_timeout = 600
        RestClient.timeout = 600
        if [:patch, :post, :put].include? verb
          response = RestClient.send(verb, uri.to_s, payload, headers)
        else
          response = RestClient.send(verb, uri.to_s, headers)
        end
        # Had to remove any html tags before the xml because xmlsimple was reading the hmtl errors on pdup and was crashing.
        return response unless response.net_http_res.body
        xml_response =  '<?xml' + response.split("<?xml").last
        html_response = response.split("<?xml").first
        puts html_response if !html_response.empty?
        # @TODO - There must be a way to change the base object (XML string to
        #   Hash) while keeping the methods...
        array_response = XmlSimple.xml_in(xml_response, { 'ForceArray' => ['item'] })
        return array_response if array_response.empty? || array_response.include?('item') || array_response['item'].nil?
        return array_response['item'].first if array_response['item'].length == 1
        array_response['item']
      rescue REXML::ParseException => xml_err
        # XML Parser error
        raise "Failed to parse server response."
      end
    end
  end
end
