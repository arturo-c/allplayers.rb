require 'rubygems'
require 'restclient'
require 'restclient/response'
require 'xmlsimple'
require 'addressable/uri'
require 'logger'
require 'active_support/base64'

# duck-punch some pretty error messages into RestClient library exceptions.
RestClient::STATUSES.each_pair do |code, message|
  RestClient::Exceptions::EXCEPTIONS_MAP[code].send(:define_method, :message) {
    response_error = ''
    if !self.response.nil?
        response_error = ' : ' + CGI::unescapeHTML(self.response.gsub(/<\/?[^>]*>/, " ").strip.gsub(/\r\n?/, ', ').squeeze(' '))
    end
    "#{http_code ? "#{http_code} " : ''}#{message}#{response_error}"
  }
end

class ApcirClient
  attr_accessor :logger

  def initialize(api_key = nil, server = 'sandbox.allplayers.com', protocol = 'http://')
    @base_uri = Addressable::URI.join(protocol + server, '/api/v1/rest/')
    @key = api_key # TODO - Not implemented in API yet.
    @session_cookies = {}
  end

  def log(target)
    @log = target
    RestClient.log = target
  end

  def login(name, pass)
    begin
      post 'user/login' , {:username => name, :password => pass}
    rescue RestClient::Exception => e
      puts "Session authentication error."
      raise #Re-raise the error.
    end
  end

  def logout()
    begin
      #[POST] {endpoint}/user/logout
      post 'user/logout'
    ensure
      @session_cookies = {} # Delete the cookies.
    end
  end

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
    #[GET] {endpoint}/node?fields=nid,title,body&parameters[uid]=1
    get 'file', filters
  end
  
  def file_create(file)
    #[POST] {endpoint}/file/ + DATA
    file[:file] = ActiveSupport::Base64.encode64s(file[:file])
    post 'file', {:file => file}
  end

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

  def group_create(title, description, location, categories, type, more_params = {})

    # Get appropriate Taxonomy term.
    # @TODO - Handle hierachical taxonomy.
    vocabulary = {}
    categories.each do |category|
      vid = self.taxonomy_vocabulary_list({:module => 'features_group_category'})['item'][0]['vid'].to_s
      tid = self.taxonomy_term_list({:name => category, :vid => vid})['item'][0]['tid'].to_s unless vid.empty?
      if vocabulary[vid]
        vocabulary[vid].push(tid)
      else
        vocabulary.merge!({vid => [tid]})
      end
    end

    required_params = {
      :og_description => description,
      :locations => {:'0' => location},
      :taxonomy => vocabulary,
      :spaces_preset_og => type.downcase,
    }

    # DOC - To specify 'other' type
    # more_params.merge!({:spaces_preset_other => 'Other'})

    # Generate a path with random title, type and random string if none given.
    # TODO - Check for collisions...
    if more_params['purl'].nil?
      purl_path = (title + ' ' + type).downcase.gsub(/[^0-9a-z]/i, '_')
      more_params.merge!({:purl => {:value => purl_path}})
    end

    # APCIHACK - Fix renamed submit button.
    more_params.merge!({:op => 'Save Group'})

    # APCIHACK - Fix non-required fields...
    more_params.merge!({
        :field_status => {:value => 'Active'},
        :field_group_mates => {:value => 'Group Mates'},
        :field_accept_amex => {:value => 'Accept'},
    })

    node_create title, 'group', nil, required_params.merge(more_params)
  end

  def event_create(title, groups, start_date, end_date, category, body = nil, more_params = {})

    # Get appropriate Taxonomy term.
    vid = self.taxonomy_vocabulary_list({:module => 'features_event_category'})['item']['vid']
    tid = self.taxonomy_term_list({:name => category, :vid => vid})['item']['tid']

    required_params = {
      :og_audience => groups, #TODO - that ain't gonna fly, need to lookup the groups.
      :taxonomy => {vid => tid},
      :field_date => {:'0' => {
          :value => start_date, # TODO - That won't work, need to figure out date format.
          :value2 => end_date, # TODO - That won't work, need to figure out date format.
        }}
    }

    node_create title, 'vevent', body, required_params.merge(more_params)
  end

  def taxonomy_vocabulary_list(filters)
    #[GET] {endpoint}/vocabulary (?fields[]=fieldname&vid=value)
    get 'vocabulary', {:parameters => filters}
  end

  def taxonomy_term_list(filters)
    #[GET] {endpoint}/term (?fields[]=fieldname&tid=value)
    get 'term' , {:parameters => filters}
  end

  def user_get(uid)
    #[GET] {endpoint}/user/{uid}
    get 'user/' + uid.to_s()
  end

  def user_get_profile(uid)
    profiles = $apci_session.node_list({
      :uid => uid.to_s,
      :type => 'profile',
    })
    node_get(profiles['item'].first['nid'])
  end

  def user_list(parameters, fields = nil)
    filters = {:parameters => parameters}
    filters[:fields] = fields unless fields.nil?
    #[GET] {endpoint}/user?fields=uid,name,mail&parameters[uid]=1
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

  def user_join_group(uid, nid)
    #[POST] {endpoint}/node/{nid}/join/{uid}
    post 'node/' + nid.to_s() + '/join/' + uid.to_s()
  end

  def user_leave_group(uid, nid)
    #[POST] {endpoint}/node/{nid}/leave/{uid}
    post 'node/' + nid.to_s() + '/leave/' + uid.to_s()
  end

  def group_roles_list(nid, uid = nil)
    #[GET] {endpoint}/node/{nid}/roles(/uid)
    if uid.nil?
      get 'node/' + nid.to_s() + '/roles/' + uid.to_s()
    else
      get 'node/' + nid.to_s() + '/roles'
    end
  end

  def group_users_list(nid)
    #[GET] {endpoint}/node/{nid}/users
    get 'node/' + nid.to_s() + '/users'
  end

  def user_groups_list(uid)
    #[GET] {endpoint}/user/{uid}/groups
    get 'user/' + uid.to_s() + '/groups'
  end

  def user_children_list(uid)
    #[GET] {endpoint}/user/{uid}/children
    get 'user/' + uid.to_s() + '/children'
  end

  def user_group_role_add(uid, nid, rid, options = {})
    #[POST] {endpoint}/node/{nid}/addrole/{uid}/{rid}
    post 'node/' + nid.to_s() + '/addrole/' + uid.to_s() + '/' + rid.to_s(), options
  end

  def user_parent_add(child_uid, parent_uid)
    #[POST] {endpoint}/user/{child_uid}/addparent/{parent_uid}
    post 'user/' + child_uid.to_s() + '/addparent/' + parent_uid.to_s()
  end

  protected
  def get(path, query = {}, headers = {})
    # @TODO - cache here (HTTP Headers?)
    begin
      uri = @base_uri.join(path)
      # TODO - Convert all query values to strings.
      uri.query_values = query unless query.empty?
      headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
      RestClient.log = @log
      response = RestClient.get(uri.to_s, headers)
      # @TODO - Review this logic - Update the cookies.
      @session_cookies.merge!(response.cookies) unless response.cookies.empty?
      # @TODO - There must be a way to change the base object (XML string to
      #   Hash) while keeping the methods...
      XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
    rescue REXML::ParseException => xml_err
      # XML Parser error
      raise "Failed to parse server response."
    end
  end

  def post(path, params = {}, headers = {})
    begin
      uri = @base_uri.join(path)
      headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
      RestClient.log = @log
      response = RestClient.post(uri.to_s, params, headers)
      # @TODO - Review this logic - Update the cookies.
      @session_cookies.merge!(response.cookies) unless response.cookies.empty?
      # @TODO - There must be a way to change the base object (XML string to
      #   Hash) while keeping the methods...
      XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
    rescue REXML::ParseException => xml_err
      # XML Parser error
      raise "Failed to parse server response."
    end
  end

  def put(path, params = {}, headers = {})
    begin
      uri = @base_uri.join(path)
      headers.merge!({:cookies => @session_cookies}) unless @session_cookies.empty?
      RestClient.log = @log
      response = RestClient.put(uri.to_s, params, headers)
      # @TODO - Review this logic - Update the cookies.
      @session_cookies.merge!(response.cookies) unless response.cookies.empty?
      # @TODO - There must be a way to change the base object (XML string to
      #   Hash) while keeping the methods...
      XmlSimple.xml_in(response, { 'ForceArray' => ['item'] })
    rescue REXML::ParseException => xml_err
      # XML Parser error
      raise "Failed to parse server response."
    end
  end
end
