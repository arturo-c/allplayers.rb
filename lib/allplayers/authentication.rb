module AllPlayers
  module Authentication
    def login(name, pass)
      begin
        post 'users/login' , {:username => name, :password => pass}
      end
    end

    def logout()
      begin
        post 'users/logout'
      end
    end
  end
end
