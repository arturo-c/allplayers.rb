module AllPlayers
  module Groups
    def group_create(title, description, location, categories, more_params = {})
      required_params = {
        :title => title,
        :description => description,
        :location => location,
        :category => categories
      }
      post 'groups', required_params.merge(more_params)
    end

    def group_set_manager(group_uuid, user_uuid, remove_previous = false)
      post 'groups/' + group_uuid.to_s + '/setmanager/' + user_uuid.to_s, {:remove_previous => remove_previous}
    end

    def group_clone(target_uuid, origin_uuid, groups_above_setting = nil)
      post 'groups/' + target_uuid + '/copy/' + origin_uuid, {:groups_above => groups_above_setting}
    end

    def group_clone_webforms(target_uuid, origin_uuid, create_new = false, user_uuid = nil)
      post 'groups/' + target_uuid + '/copywebforms/' + origin_uuid, {:new => create_new, :user_uuid => user_uuid}
    end

    def group_get(group_uuid)
      get 'groups/' + group_uuid
    end

    def group_search(params = {})
      get 'groups', params
    end

    def group_delete(group_uuid)
      delete 'groups/' + group_uuid.to_s
    end

    def group_update(group_uuid, params = {})
      put 'groups/' + group_uuid, params
    end

    def group_members_list(group_uuid, user_uuid = nil, params = {})
      if user_uuid.nil?
        get 'groups/' + group_uuid + '/members', params
      else
        get 'groups/' + group_uuid + '/members/' + user_uuid, params
      end
    end

    def group_webforms_list(group_uuid)
      get 'groups/' + group_uuid + '/webforms'
    end

    def group_roles_list(group_uuid, user_uuid = nil, params = {})
      if user_uuid.nil?
        get 'groups/' + group_uuid + '/roles', params
      else
        get 'groups/' + group_uuid + '/roles/' + user_uuid, params
      end
    end

    def group_subgroups_tree(group_uuid)
      get 'groups/' + group_uuid + '/subgroups/tree'
    end

    def set_store_payee(group_uuid, payee = nil)
      post 'group_stores/' + group_uuid + '/payee', {:payee_uuid => payee}
    end
  end
end
