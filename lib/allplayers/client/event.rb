module AllPlayers
  module Event
    def event_create(title, description, groups, date_start, date_end, nid = nil, more_params = {})
      required_params = {
        :gids => groups,
        :title => title,
        :description => description,
        :date_time => {
            :date_start => date_start,
            :date_end => date_end,
          }
      }
      if nid.nil?
        response = post 'events', required_params.merge(more_params)
      else
        more_params['eid'] = nid
        put 'events/'+nid, required_params.merge(more_params)
        response = 'update'
      end
    end
  end
end
