#!/usr/bin/ruby
require 'rubygems'
require 'apci_gdoc'
require 'apci_rest'
require 'highline/import'

def google_docs_import
  # Open a Google Docs Session
  g = ApciGoogSS.new
  puts "Connecting to Google Docs...\n"
  # TODO - Passwords in code, bleh!  Accept user input.
  g.login('user@gmail.com', '')

  # Spreadsheet search menu
  puts "Listing Spreadsheets...\n"
  spreadsheets = g.list

  choices = {'quit' => 'quit'}
  spreadsheets['feed']['entry'].each do |spreadsheet|
    choices.merge!({spreadsheet['title'] => spreadsheet})
  end

  loop do
    cmd = ask("Choose spreadsheet:  ", choices.keys.sort) do |q|
      q.readline = true
    end
    break if cmd == "quit"

    # Worksheet import menu.
    say("Fetching \"#{cmd}\"...")
    worksheets = g.get_content(choices[cmd]['content']['src'])
    # Get spreadsheet key. TODO - This looks fragile.
    key = worksheets['feed']['id'].split('/')[5]

    w_ops = {
      'quit' => 'quit',
      ':all' => {'key' => key},
    }
    w_choices = {}
    # LAME - needed for CSV tab #.
    i = 0
    worksheets['feed']['entry'].each do | worksheet |
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
      when 'quit'
        break
      when ':all'
        w_choices.each do | worksheet |
          sheet = g.get_from_csv(worksheet['key'], worksheet['order'])
          @apci_session.import_sheet(sheet, worksheet['title'])
        end
        say('Imported all sheets.')
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

# TODO - Accept user input/arguments
# Open an allplayers connection
@apci_session = ApcirClient.new(nil, 'vbox.allplayers.com')
@apci_session.login('user', '')
# Extend our API class with spreadsheet import actions.
@apci_session.extend ImportActions

# Top level menu.
choose do |menu|
  menu.prompt = "Where will we import from?"
  menu.choice(:'Google Docs') { google_docs_import }
  menu.choices(:'.ODS', :'.CSV') { abort("Sorry, don't have that yet.") }
end

@apci_session.logout