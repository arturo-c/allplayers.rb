#!/usr/bin/ruby
require 'rubygems'
require 'apci_gdoc'
require 'apci_rest'
require 'apcir_import_actions'
require 'highline/import'

def google_docs_import
  # Open a Google Docs Session
  g = ApciGoogSS.new
  puts "Connecting to Google Docs...\n"
  g.login('user', '')
  #g.interactive_login

  # Spreadsheet search menu
  puts "Listing Spreadsheets...\n"
  spreadsheets = g.list_spreadsheets

  choices = {':quit' => ':quit'}
  spreadsheets['entry'].each do |spreadsheet|
    choices.merge!({spreadsheet['title'] => spreadsheet})
  end

  loop do
    cmd = ask("Choose spreadsheet:  ", choices.keys.sort) do |q|
      q.readline = true
    end
    break if cmd == ":quit"

    # Worksheet import menu.
    say("Fetching \"#{cmd}\"...")
    worksheets = g.get_content(choices[cmd]['content']['src'])

    # Get spreadsheet key. TODO - This looks fragile.
    key = worksheets['id'].split('/')[5]

    w_ops = {
      ':quit' => ':quit',
      ':all' => {'key' => key},
    }
    w_choices = {}
    # LAME - needed for CSV tab #.
    i = 0
    worksheets['entry'].each do | worksheet |
      w_choices.merge!({worksheet['title'] => worksheet})
      w_choices[worksheet['title']].merge!({'order' => i})
      w_choices[worksheet['title']].merge!({'key' => key})
      i = i + 1
    end
    loop do
      cmd = ask("Choose worksheet to import:  ", w_choices.merge(w_ops).keys.sort) do |q|
        q.readline = true
      end
      case cmd
      when ':quit'
        break
      when ':all'
        say('Importing all sheets.')
        w_choices.each do | worksheet |
          sheet = g.get_from_csv(worksheet['key'], worksheet['order'])
          @apci_session.import_sheet(sheet, worksheet['title'])
        end
        break
      else
        say("Importing \"#{cmd}\"...")
        sheet = g.get_from_csv(w_choices[cmd]['key'], w_choices[cmd]['order'])
        @apci_session.import_sheet(sheet, cmd)
      end
    end
    # End Worksheet import menu
  end
  # End Spreadsheet search menu
end

# Logging TODO - Get this working. Setup a place to log RestClient requests.
path = Dir.pwd + '/apci_import_logs'
begin
  FileUtils.mkdir(paths)
rescue
  # Do nothing, it's already there?
ensure
  ENV['RESTCLIENT_LOG']= path + '/REST.log'
end
# End Logging

# TODO - Accept program arguments for server connection.
# Open an allplayers connection
@apci_session = ApcirClient.new(nil, 'vbox.allplayers.com')

# Extend our API class with import and interactive actions.
@apci_session.extend ImportActions
#@apci_session.interactive_login
# TODO - Passwords in code = bad! Get password from program arg.
puts 'Logging into Allplayers.com to save time.'
@apci_session.login('user', '')

puts 'Strait into Google Docs to save time.'
google_docs_import
=begin
# Top level menu.
choose do |menu|
  menu.prompt = "Where will we import from?"
  menu.choice(:'Google Docs') { google_docs_import }
  menu.choices(:'.ODS', :'.CSV') { abort("Sorry, don't have that yet.") }
end
=end

@apci_session.logout