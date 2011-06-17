# Monkey patch GData to support compression.  This probably shouldn't be
# included on Ruby 1.9+ because Net::HTTP supports compression by default.
require 'helpers/http_encoding_helper'
module GData
  module HTTP

    # This is the default implementation of the HTTP layer that uses
    # Net::HTTP. You could roll your own if you have different requirements
    # or cannot use Net::HTTP for some reason.
    class DefaultService

      # Take a GData::HTTP::Request, execute the request, and return a
      # GData::HTTP::Response object.
      def make_request(request)
        url = URI.parse(request.url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        case request.method
        when :get
          req = Net::HTTP::Get.new(url.request_uri)
        when :put
          req = Net::HTTP::Put.new(url.request_uri)
        when :post
          req = Net::HTTP::Post.new(url.request_uri)
        when :delete
          req = Net::HTTP::Delete.new(url.request_uri)
        else
          raise ArgumentError, "Unsupported HTTP method specified."
        end

        case request.body
        when String
          req.body = request.body
        when Hash
          req.set_form_data(request.body)
        when File
          req.body_stream = request.body
          request.chunked = true
        when GData::HTTP::MimeBody
          req.body_stream = request.body
          request.chunked = true
        else
          req.body = request.body.to_s
        end

        request.headers.each do |key, value|
          req[key] = value
        end
        req['Accept-Encoding'] = 'gzip, deflate'

        request.calculate_length!

        res = http.request(req)

        response = Response.new
        response.body = res.plain_body

        response.headers = Hash.new
        res.each do |key, value|
          response.headers[key] = value
        end
        response.status_code = res.code.to_i
        return response
      end
    end
  end
end