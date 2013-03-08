module AllPlayers
  module Users
    def user_create(email, firstname, lastname, birthday, gender, more_params = {})
      required_params = {
        :email => email,
        :firstname => firstname,
        :lastname => lastname,
        :birthday => birthday,
        :gender => gender,
      }
      post 'users', required_params.merge(more_params)
    end

    def user_get_email(email = nil)
      get 'users', {:email => email} if !email.nil?
    end

    def user_get(uuid = nil)
      get 'users/' + uuid.to_s() if !uuid.nil?
    end

    def user_children_list(uuid)
      get 'users/' + uuid.to_s() + '/children'
    end

    def user_create_child(parent_uuid, firstname, lastname, birthday, gender, more_params = {})
      required_params = {
        :firstname => firstname,
        :lastname => lastname,
        :birthday => birthday,
        :gender => gender,
      }
      post 'users/' + parent_uuid.to_s() + '/addchild', required_params.merge(more_params)
    end

    def user_groups_list(user_uuid, params = {})
      get 'users/' + user_uuid + '/groups', params
    end

    def user_join_group(group_uuid, user_uuid, role_name = nil, options = {}, webform_id = nil)
      post 'groups/' + group_uuid + '/join/' + user_uuid, {:org_webform_uuid => webform_id, :role_name => role_name.to_s, :role_options => options}
    end

    def user_group_add_role(group_uuid, user_uuid, role_uuid, params = {})
      post 'groups/' + group_uuid + '/addrole/' + user_uuid + '/' + role_uuid, params
    end
  end
end