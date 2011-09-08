require 'rubygems'
require 'xmlsimple'
require 'logger'
require 'active_support/base64'
require 'allplayers'

class ApcirClient < AllPlayers::Client
  attr_accessor :logger

  def log(target)
    @log = target
    RestClient.log = target
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

  def group_create(title, description, categories, location, type, more_params = {})

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
      :field_location => {:'0' => location},
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

    # APCIHACK - Fix non-required fields...
    more_params.merge!({
        :field_status => {:value => 'Active'},
        :field_group_mates => {:value => 'Group Mates'},
        :field_accept_amex => {:value => 'Accept'},
    })

    node_create title, 'group', nil, required_params.merge(more_params)
  end

  def taxonomy_vocabulary_list(filters)
    #[GET] {endpoint}/vocabulary (?fields[]=fieldname&vid=value)
    get 'vocabulary', {:parameters => filters}
  end

  def taxonomy_term_list(filters)
    #[GET] {endpoint}/term (?fields[]=fieldname&tid=value)
    get 'term' , {:parameters => filters}
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

  def user_group_role_add(uid, nid, rid, options = {})
    #[POST] {endpoint}/node/{nid}/addrole/{uid}/{rid}
    post 'node/' + nid.to_s() + '/addrole/' + uid.to_s() + '/' + rid.to_s(), options
  end

end