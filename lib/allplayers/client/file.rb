module AllPlayers
  module File
    def file_get(fid, file_contents = true)
      #[GET] {endpoint}/file/{fid}
      file = get 'file/' + fid.to_s(), {:file_contents => file_contents}
      if file_contents
        file['contents'] = ActiveSupport::Base64.decode64(file['file'])
      end
      file
    end

    def file_list(parameters, fields = nil)
      filters = {:parameters => parameters}
      filters[:fields] = fields unless fields.nil?
      get 'file', filters
    end

    def file_create(file)
      #[POST] {endpoint}/file/ + DATA
      file[:file] = ActiveSupport::Base64.encode64s(file[:file])
      post 'file', {:file => file}
    end
  end
end