require 'rubygems'
require 'restclient'
require 'restclient/response'
# Hash.from_xml()
require 'active_support'
require "addressable/uri"

class ApcirClient

  def initialize(api_key = nil, base_url = 'www.allplayers.com', protocol = 'http://')
    @uri = Addressable::URI.join(protocol + base_url, '/api/v1/rest/')
    @key = api_key
  end

  def login(name, pass)
    begin
      #[POST] {endpoint}/user/login + DATA (name, pass)
      uri = Addressable::URI.join(@uri, 'user/login')
      response = RestClient.post(uri.to_s, {:name => name, :pass => pass})
      @session_cookies = response.cookies
      Hash.from_xml(response)['result']
    rescue
      puts "Session authentication failed."
    end
  end

  def logout()
    #[POST] {endpoint}/user/logout
    post 'user/logout'
  end

  def node_get(nid)
    #[GET] {endpoint}/node/{nid}
    get 'node/' + nid.to_s()
  end

  def node_list(filters)
    #[GET] {endpoint}/node (?fields[]=fieldname&nid=value)
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
    post 'node', required_params.merge(more_params)
  end

  def group_create(title, description, location, category, type, more_params = {})

    # Get appropriate Taxonomy term.
    # @TODO - Handle hierachical taxonomy.  
    vid = self.taxonomy_vocabulary_list({:module => 'features_group_category'})['item']['vid']
    tid = self.taxonomy_term_list({:name => category, :vid => vid})['item']['tid']

    # PURL preset names are lowercase.
    type = type.downcase

    required_params = {
      :og_description => description,
      :locations => {:'0' => location},
      :taxonomy => {vid => tid},
      :spaces_preset_og => type,
    }

    # Set 'other' type, may not be needed.
    if (type == 'other' && more_params['spaces_preset_other'].nil?)
      more_params.merge!({:spaces_preset_other => 'other'})
    end

    # Generate a path if none given.
    if more_params['purl'].nil?
      purl_path = (title + ' ' + type).downcase.gsub(/[^0-9a-z]/i, '_')
      more_params.merge!({:purl => {:value => purl_path}})
    end

    # APCIHACK - Fix renamed submit button.
    more_params.merge!({:op => 'Save Group'})

    # APCIHACK - Fix non-required fields...
    more_params.merge!({
        :field_status => {:'0' => 'Active'},
        :field_group_mates => {:'0' => 'Group Mates'}
    })

    #[POST] {endpoint}/node + DATA (form_state for node_form)
    node_create title, 'group', nil, required_params.merge(more_params)
  end

  def taxonomy_vocabulary_list(filters)
    #[GET] {endpoint}/vocabulary (?fields[]=fieldname&vid=value)
    get 'vocabulary', filters
  end

  def taxonomy_term_list(filters)
    #[GET] {endpoint}/term (?fields[]=fieldname&tid=value)
    get 'term' , filters
  end

  def user_get(uid)
    #[GET] {endpoint}/user/{uid}
    get 'user/' + uid.to_s()
  end

  def user_list(filters)
    #[GET] {endpoint}/user?fieldname=value
    get 'user', filters
  end

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
      :notify => '1', # Send welcome email.
      :force_password_change => '1', # Force password change on first login.
    }.merge(more_params)

    #[POST] {endpoint}/user + DATA (form_state for user_register form
    post 'user', required_params.merge(more_params)
  end

  def user_join_group(uid, nid)
    #[POST] {endpoint}/node/{nid}/join/{uid}
    post 'node/' + nid.to_s() + '/join/' + uid.to_s()
  end

  def user_leave_group(uid, nid)
    #[POST] {endpoint}/node/{nid}/leave/{uid}
    post 'node/' + nid.to_s() + '/leave/' + uid.to_s()
  end

  def group_roles_list(nid)
    #[GET] {endpoint}/node/{nid}/roles
    get 'node/' + nid.to_s() + '/roles'
  end

  def user_group_role_add(uid, nid, rid)
    #[POST] {endpoint}/node/{nid}/addrole/{uid}/{rid}
    post 'node/' + nid.to_s() + '/addrole/' + uid.to_s() + '/' + rid.to_s()
  end

  protected
  def get(path, query = nil, headers = {})
    # @TODO - cache here (HTTP Headers?)
    begin
      uri = Addressable::URI.join(@uri, path)
      uri.query_values = query if query
      response = RestClient.get(uri.to_s, headers.merge({:cookies => @session_cookies}))
      # @TODO - Update the cookies?
      # @TODO - There must be a way to change the base object (XML string to
      #   Hash) while keeping the methods...
      Hash.from_xml(response)['result']
    rescue
      puts "\nGET failed: " + $!
    end
  end

  def post(path, params = {}, headers = {})
    begin
      uri = Addressable::URI.join(@uri, path)
      response = RestClient.post(uri.to_s, params, headers.merge({:cookies => @session_cookies}))
      # @TODO - Update the cookies?
      # @TODO - There must be a way to change the base object (XML string to
      #   Hash) while keeping the methods...
      Hash.from_xml(response)['result']
    rescue
      puts "\nPOST failed: " + $!
    end
  end
end
