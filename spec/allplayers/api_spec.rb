require 'helper'

describe AllPlayers::API do
  before do
    def get_args
      # If any environment variable set, skip argument handling.
      if ENV.has_key?('APCI_REST_TEST_HOST')
        $apci_rest_test_host = ENV['APCI_REST_TEST_HOST']
        $apci_rest_test_user = ENV['APCI_REST_TEST_USER']
        $apci_rest_test_pass = ENV['APCI_REST_TEST_PASS']
        return
      end

      $apci_rest_test_user = Etc.getlogin if $apci_rest_test_user.nil?
      $apci_rest_test_pass = nil if $apci_rest_test_pass.nil?

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
        [ '-p',       GetoptLong::REQUIRED_ARGUMENT]
      )

      opts.each do |opt, arg|
        case opt
          when '--help'
            RDoc::usage
          when '-p'
            $apci_rest_test_pass = arg
        end
      end

      RDoc::usage if $apci_rest_test_pass.nil?

      # Handle default argument => host to target for import and optional user,
      # (i.e. user@sandbox.allplayers.com).
      if ARGV.length != 1
        puts "No host argument, connecting to default host (try --help)"
        $apci_rest_test_host = nil
      else
        host_user = ARGV.shift.split('@')
        $apci_rest_test_user = host_user.shift if host_user.length > 1
        $apci_rest_test_host = host_user[0]
        puts 'Connecting to ' + $apci_rest_test_host
      end
    end
    if $login_response.nil?
      if $apci_rest_test_user.nil? || $apci_rest_test_pass.nil?
        get_args
      end

      if $apci_session.nil?
        $apci_session = AllPlayers::Client.new(nil, $apci_rest_test_host)
      end

      # End arguments

      # TODO - Log only with argument (-l)?
      # Make a folder for some logs!
      path = Dir.pwd + '/test_logs'
      begin
        FileUtils.mkdir(path)
      rescue
        # Do nothing, it's already there?  Perhaps catch a more specific error?
      ensure
        logger = Logger.new(path + '/test.log', 'daily')
        logger.level = Logger::DEBUG
        logger.info('initialize') { "Initializing..." }
        $apci_session.log(logger)
      end

      # Account shouldn't be hard coded!
      $login_response = $apci_session.login($apci_rest_test_user, $apci_rest_test_pass)
    end
    $apci_session = $apci_session
  end
  it "should return a valid session." do
    $apci_session.should_not == nil
  end

end
