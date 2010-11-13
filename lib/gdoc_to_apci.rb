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
require 'logger'
require 'yaml'
require 'active_support'

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
#  spreadsheets = g.list_spreadsheets
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
        'title' => 'Matts Import Template',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0Ahq9WekqwsExdDU0MmluaUJWZkRaZXJqQWx0Ny1VSnc/private/full',
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
      {
        'title' => 'YMCA-BIG GAME PROMO IMPORT (FINAL)',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydDR5OFpjQ1hNV2gzcnZta21TVE5zZEE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'PAL - BIG GAME PROMO import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydFl2aHdGd200elZQa0pTZW9zckRSMVE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'BGCA Southwest recovered list',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AtryEYO1I48NdE9Mcy1DMUFzMExicXl2OGN1bXZlTmc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'BGCA Southest IMPORT',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydGl3amtmYThNVDRqdjk0bVRBS2VWTmc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Odessa Tackle Football 2010 Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydDgwcEwwVEtvRjNLY3FucGhBUVp6b2c/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Red Oak ISD Football',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0Ag2ekyd5CABldEE1OXJ5Zll0T3JiWkMta1FmWVNPRXc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'bgc pacific import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydFJmdGZIZFpGdjJHbmdXa0ozREJWVHc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Waxahachie Volleyball Coaches',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0Agjj5uTMDbUxdE1XTGlTOFBkNzRtakpLcEdRLTFCMmc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Waxahachie Flag Football Coaches Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0Agjj5uTMDbUxdE9qb0Y4cjVnUkNhZmt4dlhkU2JtZVE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Waxahachie Football Parents and Players',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydDJseUJGYjFjckh1Vld2UzI1UlRlRlE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Waxahachie Volleyball Parents and Players',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydHVkbzFJakpjdktVcHdGXzEwZjAtd1E/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Frisco Y Coaches Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AjgSHHY0WHyydDlqSzMzSkFHalpHV3hhaUQzWjk3TUE/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Rockwall Y Coaches Import',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AoDhKnZl3R6pdGxjaWRlYUZhQW5mMVpwOV9ZZk0zZXc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      },
      {
        'title' => 'Rockwall Y Players/Parents Import 2',
        'content' => {
          'src' => 'https://spreadsheets.google.com/feeds/worksheets/0AoDhKnZl3R6pdEFRN3AtakxwNnhkMm9fbFo3ODlUeHc/private/full',
          'type' => 'application/atom+xml;type=feed',
        }
      }
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
