require 'allplayers/error'

module AllPlayers
  class Error
    # Raised when JSON parsing fails
    class DecodeError < AllPlayers::Error
    end
  end
end