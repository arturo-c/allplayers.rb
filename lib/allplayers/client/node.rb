module AllPlayers
  module Node
    def node_files_get(nid, file_contents = true)
      #[GET] {endpoint}/file/nodeFiles + PARAMS
      get 'file/nodeFiles', {:nid => nid.to_s, :file_contents => file_contents}
    end

    def node_get(nid)
      #[GET] {endpoint}/node/{nid}
      get 'node/' + nid.to_s()
    end

    def node_list(parameters, fields = nil)
      filters = {:parameters => parameters}
      filters[:fields] = fields unless fields.nil?
      #[GET] {endpoint}/node?fields=nid,title,body&parameters[uid]=1
      get 'node', filters
    end

    def node_create(title, type, body = nil, more_params = {})
      required_params = {
        :title => title,
        :type => type,
      }

      # Add a body if there is one.
      more_params.merge!({:body => body}) if body

      # Defaults, can be overridden.
      more_params = {
        :language => 'en',
      }.merge(more_params)

      #[POST] {endpoint}/node + DATA (form_state for node_form)
      post 'node', {:node => required_params.merge(more_params)}
    end

    def node_update(nid, params)
      #[PUT] {endpoint}/node + DATA (form_state for node_form)
      put 'node/' + nid.to_s, {:node => params}
    end
  end
end
