module AllPlayers
  # Custom error class for rescuing from all AllPlayers errors
  class Error < StandardError
    attr_reader :code, :error

    # Initializes a new Error object
    #
    # @param response [Hash]
    # @return [AllPlayers::Error]
    def initialize(response)
      @code = response.code
      @error = response.body
    end
  end
end