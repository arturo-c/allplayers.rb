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
      # TODO - Handle CAPTCHA requests.
      # clientlogin(username, password, captcha_token = nil, captcha_answer = nil, service = nil, account_type = nil)
      @client.clientlogin(user, pass, captcha_token, captcha_answer, service, account_type)
    rescue GData::Client::AuthorizationError
      $dz.error("Login Failure", "Something went wrong while logging you in. Check the credentials")
    rescue GData::Client::CaptchaError
      $dz.error("Login Failure", "There was an error during login, try to login to Google Docs in your browser and then try again.")
    rescue SocketError
      $dz.error("No connection", "Cannot connect to the Google Docs service, are you connected to the internet?")
    rescue Exception
      $dz.error("Unkown error", "An unkown error happened.")
    else
      sleep(1)
    end
  end

  def interactive_login
    user = ask("Enter your Google Docs e-mail:  ") { }
    pass = ask("Enter your Google Docs password:  ") { |q| q.echo = false }
    self.login( user, pass )
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
