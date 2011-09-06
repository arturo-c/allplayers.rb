require 'rubygems'
require 'restclient'

# monkey patch RestClient to support custom timeouts.
module RestClient

  def self.get(url, headers={}, &block)
    Request.execute(:method => :get, :url => url, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  def self.post(url, payload, headers={}, &block)
    Request.execute(:method => :post, :url => url, :payload => payload, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  def self.put(url, payload, headers={}, &block)
    Request.execute(:method => :put, :url => url, :payload => payload, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  def self.delete(url, headers={}, &block)
    Request.execute(:method => :delete, :url => url, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  def self.head(url, headers={}, &block)
    Request.execute(:method => :head, :url => url, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  def self.options(url, headers={}, &block)
    Request.execute(:method => :options, :url => url, :headers => headers, :timeout => @timeout, :open_timeout => @open_timeout, &block)
  end

  class << self
    attr_accessor :timeout
    attr_accessor :open_timeout
  end
end

# monkey patch some pretty error messages into RestClient library exceptions.
RestClient::STATUSES.each_pair do |code, message|
  RestClient::Exceptions::EXCEPTIONS_MAP[code].send(:define_method, :message) {
    response_error = ''
    if !self.response.nil?
        response_error = ' : ' + CGI::unescapeHTML(self.response.gsub(/<\/?[^>]*>/, " ").strip.gsub(/\r\n?/, ', ').squeeze(' '))
    end
    "#{http_code ? "#{http_code} " : ''}#{message}#{response_error}"
  }
end
