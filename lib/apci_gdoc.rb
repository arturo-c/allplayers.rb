require 'rubygems'
require 'gdata'
require "addressable/uri"
require 'highline/import'
require 'nokogiri'
require 'helpers/gdata_compression'

# Stop EOF errors in Highline
HighLine.track_eof = false

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
    user = ask("Enter your Google Docs e-mail:  ") { |q| q.echo = true } if user.nil?
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
    get_content(uri.to_s)
  rescue
    puts "Unable to list spreadsheets: " + $!
  end

  def get_content(href)
    # TODO - Maintain SSL/HTTPS...
    uri = Addressable::URI.parse(href)
    response = @client.get(uri.to_s)
    File.open('last_gdoc.xml', 'w') {|f| f.write(response.body) }
    Nokogiri::XML(response.body)
  rescue
    puts "Unable to retrieve spreadsheet: " + $!
  end

  # Traverse worksheet Nokogiri::XML GData Worksheet feed looking for cells and save them into a 2d array.
  def worksheet_feed_to_a(xml)
    worksheet = []
    xml.xpath('xmlns:feed/xmlns:entry/gs:cell').each do |cell|
      row = cell.attribute('row').content.to_i - 1
      col = cell.attribute('col').content.to_i - 1
      worksheet[row] = [] if worksheet[row].nil?
      worksheet[row][col] = cell.text
    end
    worksheet
  end
end
