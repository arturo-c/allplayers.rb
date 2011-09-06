module AllPlayers
  module Auth
    module Session
      def login(name, pass)
        begin
          post 'user/login' , {:username => name, :password => pass}
        rescue RestClient::Exception => e
          puts "Session authentication error."
          raise #Re-raise the error.
        end
      end

      def logout()
        begin
          #[POST] {endpoint}/user/logout
          post 'user/logout'
        ensure
          @session_cookies = {} # Delete the cookies.
        end
      end
    end
  end
end
