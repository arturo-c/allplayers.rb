require 'rubygems'
require 'gdata'
require 'fastercsv'
require 'xmlsimple'
require "addressable/uri"
require 'highline/import'

class ApciGoogSS
  def initialize(protocol = 'https')
    @client = GData::Client::Spreadsheets.new
    @base_uri = Addressable::URI.parse(protocol +'://spreadsheets.google.com/')
  end

  def login(user, pass, captcha_token = nil, captcha_answer = nil, service = nil, account_type = nil)
    begin
      @client.clientlogin(user, pass, captcha_token, captcha_answer, service, account_type)
    rescue GData::Client::AuthorizationError
      puts "Login Failure, Something went wrong while logging you in. Check the credentials"
      raise
    rescue GData::Client::CaptchaError => e
      puts "Login Failure, CAPTCHA Requested."
      puts "Token: #{e.token}\n"
      puts "http://www.google.com/accounts/#{e.url}"
      raise
    rescue SocketError
      puts "No connection, Cannot connect to the Google Docs service, are you connected to the internet?"
      raise
    end
  end

  def interactive_login(user = nil, pass = nil, captcha_token = nil, captcha_answer = nil, service = nil, account_type = nil)
    user = ask("Enter your Google Docs e-mail:  ") { } if user.nil?
    pass = ask("Enter your Google Docs password:  ") { |q| q.echo = false } if pass.nil?
    self.login(user, pass, captcha_token, captcha_answer, service, account_type)
  rescue GData::Client::AuthorizationError
    pass = nil
    retry
  rescue GData::Client::CaptchaError => e
    captcha_answer = ask("Enter the CAPTCHA Text:  ") { }
    captcha_token = e.token
    retry
  end

  def list_spreadsheets
    uri = @base_uri.join('feeds/spreadsheets/private/full')
    feed = @client.get(uri.to_s)
    XmlSimple.xml_in(feed.body, { 'ForceArray' => ['entry'] })
  rescue
    puts "Unable to list spreadsheets: " + $!
  end

  def get_content(href)
    # TODO - Maintain SSL/HTTPS...
    uri = Addressable::URI.parse(href)
    feed = @client.get(uri.to_s)
    XmlSimple.xml_in(feed.body, { 'ForceArray' => ['entry'] })
  rescue
    puts "Unable to retrieve spreadsheet: " + $!
  end

  def get_from_csv(key, tab)
    begin
      uri = @base_uri.join('pub')
      uri.query_values = {:key => key, :single => 'true', :gid => tab.to_s, :output => 'csv', :hl => 'en'}
      feed = @client.get(uri.to_s)
    rescue
      puts "Failed to get spreadsheet CSV.  Did you publish the sheet?\n"
      puts 'URI: ' + uri.to_s
      puts $!
    else
      begin
        FasterCSV.parse(feed.body, {:converters => :all} )
      rescue
        puts 'Failed to parse CSV'
      end
    end
  end
end
