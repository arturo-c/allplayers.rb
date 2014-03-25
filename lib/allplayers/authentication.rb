module AllPlayers
  module Authentication
    def login(name, pass)
      begin
        post 'user/login' , {:username => name, :password => pass}
      end
    end

    def logout()
      begin
        post 'user/logout'
      end
    end
  end
end
