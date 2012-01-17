module AllPlayers
  module Event
    def event_create(title, description, groups, date_start, date_end, more_params = {})
      required_params = {
        :gids => groups,
        :title => title,
        :description => description,
        :date_time => {
            :start => date_start,
            :end => date_end,
          }
      }
      response = post 'events', required_params.merge(more_params)
    end
    def event_update(uuid, update_params)
      put 'events/'+uuid, update_params
    end
  end
end
