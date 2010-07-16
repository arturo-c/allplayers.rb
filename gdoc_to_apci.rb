#!/usr/bin/ruby
require 'rubygems'
require 'apci_gdoc'
require 'apci_rest'
require 'php_serialize'
require 'highline/import'

def google_docs_import
  # Open a Google Docs Session
g = ApciGoogSS.new
g.login('user@gmail.com', '')

# @TODO - This is gross, query ATOM/RSS, list available spreadsheets.
spreadsheets = {}
spreadsheets['import'] = '0AnrE8fZqLiAXdEFYQ3hpelk2VUFPTWRvTWRPSFQzM3c'
sheets = {}
sheets[0] = 'Users'
sheets[1] = 'Groups'
sheets[2] = 'Events'
sheets[3] = 'Users in Groups'
#puts spreadsheets[ARGV[0]]

sheets.each { | tab, fname |
  sheet = g.get_from_csv(spreadsheets[ARGV[0]], tab)
  @apci_session.import_sheet(sheet, fname)
}
end

# @TODO - Get this working. Setup a place to log RestClient requests.
path = Dir.pwd + '/apci_import_logs'
begin
  FileUtils.mkdir(paths)
rescue
  # Do nothing, it's already there?
ensure
  ENV['RESTCLIENT_LOG']= path + '/REST.log'
end

# @TODO - Accept user input/arguments
# Open an allplayers connection
@apci_session = ApcirClient.new(nil, 'vbox.allplayers.com')
@apci_session.login('user', '')
# Extend our API class with spreadsheet import actions.
@apci_session.extend ImportActions

choose do |menu|
  menu.prompt = "Where will we import from?"
  menu.choice(:'Google Docs') { google_docs_import }
  menu.choices(:'.ODS', :'.CSV') { abort("Sorry, don't have that yet.") }
end

@apci_session.logout