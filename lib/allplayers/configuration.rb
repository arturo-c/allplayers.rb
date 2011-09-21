module AllPlayers
  module Configuration
    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end
  end
end
