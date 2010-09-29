#!/usr/bin/ruby
# == Synopsis
#
# gdoc_to_apci: Tool for importing spreadsheets from Google Docs to
# Allplayers.com servers.
#
# == Usage
#
# gdoc_to_apci [OPTS] ... [USER@HOST]|[HOST]
#
# OPTS:
#  -h, --help                  show this help (ignores other options)
#  -p                          session authentication password
#      --gdoc-mail             Google Docs login name (email)
#      --gdoc-pass             Google Docs password
#
# HOST: The target server for imported items (e.g. demo.allplayers.com).

require 'apci_gdoc'
require 'apci_rest'
require 'apcir_import_actions'
require 'rubygems'
require 'getoptlong'
require 'rdoc/usage'
require 'highline/import'
require 'etc'

# Stop EOF errors in Highline
HighLine.track_eof = false

def google_docs_import
  # Open a Google Docs Session
  g = ApciGoogSS.new
  puts "Connecting to Google Docs...\n"
  g.interactive_login(@gdoc_mail, @gdoc_pass)
  puts

  # Spreadsheet search menu
  puts "Listing Spreadsheets...\n"
  #spreadsheets = g.list_spreadsheets
  # APCIHACK - GPRATT - Spreadsheet listing doesn't work on allplayers.com domain.
  spreadsheets = {
    'entry' => [
      {
        'title' => 'Import Template',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydDhlZ2dyXzBmcW5OQkVRclhweEdyeVE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Apache optimist Football Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0Ai7w3-2CeY-ddG8wLWtuWmJoeTQwM0dNRXppRTdfbHc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Benton County Youth Football Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AqPrqPEA9f2YdC1HYzhCZkN5N00tcU9mZjNRN1RzTlE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
    ]
  }

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

# Get arguments
user = Etc.getlogin
pass = nil
@gdoc_mail = nil
@gdoc_pass = nil

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '-p',       GetoptLong::REQUIRED_ARGUMENT],
  [ '--gdoc-mail',       GetoptLong::REQUIRED_ARGUMENT],
  [ '--gdoc-pass',       GetoptLong::REQUIRED_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
    when '-p'
      pass = arg
    when '--gdoc-mail'
      @gdoc_mail = arg
    when '--gdoc-pass'
      @gdoc_pass = arg
  end
end

# Handle default argument => host to target for import and optional user,
# (i.e. user@sandbox.allplayers.com).
if ARGV.length != 1
  puts "No host argument, default used (try --help)"
  @apci_session = ApcirClient.new
else
  host = ARGV.shift.split('@')
  user = host.shift if host.length > 1
  puts 'Connecting to ' + host[0] + '...'
  @apci_session = ApcirClient.new(nil, host[0])
end
# End arguments

# Setup Logging.
path = Dir.pwd + '/apci_import_logs'
begin
  FileUtils.mkdir(path)
rescue
  # Do nothing, it's already there?  Perhaps you should catch a more specific
  # message.
ensure
  logger = Logger.new(path + '/import_apci.' + Time.now.to_i.to_s + '.log')
  logger.level = Logger::DEBUG
  logger.info('initialize') { "Initializing..." }
end

# End Logging.
@apci_session.log(logger)

# Extend our API class with import and interactive actions.
@apci_session.extend ImportActions
@apci_session.interactive_login(user,pass)

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
logger.close
