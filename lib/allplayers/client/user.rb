module AllPlayers
  module User
    def user_create(mail, fname, lname, gender, birthdate, more_params = {})
      # Parse the gender to CCK field def.
      case gender.downcase
      when 'male', 'm'
        gender = '1'
      when 'female', 'f'
        gender = '2'
      end

      required_params = {
        :mail => mail,
        :field_firstname => {:'0' => {:value => fname}},
        :field_lastname => {:'0' => {:value => lname}},
        :field_user_gender => {:'0' => {:value => gender}},
        :field_birth_date => {:'0' => {:value => {
              :month => birthdate.mon.to_s(),
              :hour => '0',
              :minute => '0',
              :second => '0',
              :day => birthdate.mday.to_s(),
              :year => birthdate.year.to_s(),
            }}},
      }

      # Defaults, can be overridden.
      more_params = {
        # Send welcome email.
        :notify => '1',
        # Force password change on first login.
        :force_password_change => '1',
        # Generate a password meeting policy standards.
        :pass => ((0...8).map{ (('a'..'z').to_a + ('A'..'Z').to_a + ('2'..'9').to_a)[rand(60)] } + (0...2).map{ (('a'..'z').to_a)[rand(26)] } + (0...2).map{ (('A'..'Z').to_a)[rand(26)] } + (0...2).map{ (('2'..'9').to_a)[rand(8)] } + (0...2).map{ (['!','$','&','@'])[rand(4)] }).shuffle.join,
      }.merge(more_params)

      #[POST] {endpoint}/user + DATA (form_state for user_register form
      response = post 'user', {:account => required_params.merge(more_params)}
    ensure
      # APCIHACK - Load up user to build cache.
      self.user_get(response['uid']) unless response.nil?
    end

    def user_get(uid)
      #[GET] {endpoint}/user/{uid}
      get 'user/' + uid.to_s()
    end

    def user_list(parameters, fields = nil)
      filters = {:parameters => parameters}
      filters[:fields] = fields unless fields.nil?
      #[GET] {endpoint}/user?fields=uid,name,mail&parameters[uid]=1
      get 'user', filters
    end

    def user_groups_list(uid)
      #[GET] {endpoint}/user/{uid}/groups
      get 'user/' + uid.to_s() + '/groups'
    end

    def user_children_list(uid)
      #[GET] {endpoint}/user/{uid}/children
      get 'user/' + uid.to_s() + '/children'
    end

    def user_parent_add(child_uid, parent_uid)
      #[POST] {endpoint}/user/{child_uid}/addparent/{parent_uid}
      post 'user/' + child_uid.to_s() + '/addparent/' + parent_uid.to_s()
    end

    def user_delete(uid)
      delete 'user/' + uid.to_s
    end

    def user_get_profile(uid)
      profiles = $apci_session.node_list({
        :uid => uid.to_s,
        :type => 'profile',
      })
      node_get(profiles['item'].first['nid'])
    end

    def user_join_group(uid, nid)
      #[POST] {endpoint}/node/{nid}/join/{uid}
      post 'node/' + nid.to_s() + '/join/' + uid.to_s()
    end

    def user_leave_group(uid, nid)
      #[POST] {endpoint}/node/{nid}/leave/{uid}
      post 'node/' + nid.to_s() + '/leave/' + uid.to_s()
    end

    def user_group_role_add(uid, nid, rid, options = {})
      #[POST] {endpoint}/node/{nid}/addrole/{uid}/{rid}
      post 'node/' + nid.to_s() + '/addrole/' + uid.to_s() + '/' + rid.to_s(), options
    end

    def public_user_get(uuid = nil)
      get 'users/' + uuid.to_s() if !uuid.nil?
    end

    def public_user_get_email(email = nil)
      get 'users', {:email => email} if !email.nil?
    end

    def public_children_add(parent_uuid, firstname, lastname, birthday, gender, more_params = {})
      required_params = {
        :firstname => firstname,
        :lastname => lastname,
        :birthday => birthday,
        :gender => gender,
      }
      post 'users/' + parent_uuid.to_s() + '/addchild', required_params.merge(more_params)
    end

    def public_user_children_list(uuid)
      get 'users/' + uuid.to_s() + '/children'
    end
  end
end