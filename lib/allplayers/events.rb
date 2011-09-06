module AllPlayers
  module Events
    def event_create(title, description, groups, date_start, date_end, more_params = {})
      required_params = {
        :gids => groups,
        :title => title,
        :description => description,
        :date_time => {
            :date_start => date_start, 
            :date_end => date_end, 
          }
      }
      post 'events', required_params.merge(more_params)
    end
  end
end
