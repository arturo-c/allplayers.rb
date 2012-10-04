module AllPlayers
  module Groups
    def group_create(title, description, location, categories, type, more_params = {})

      # Get appropriate Taxonomy term.
      # @TODO - Handle hierachical taxonomy.
      vocabulary = {}
      categories.each do |category|
        vid = self.taxonomy_vocabulary_list({:module => 'features_group_category'})['item'][0]['vid'].to_s
        tid = self.taxonomy_term_list({:name => category, :vid => vid})['item'][0]['tid'] unless vid.empty?
        tid[0].to_s
        if vocabulary[vid]
          vocabulary[vid].push(tid)
        else
          vocabulary.merge!({vid => [tid]})
        end
      end

      # TODO - Check for collisions...
      if more_params['purl'].nil?
        purl_path = (title + ' ' + type).downcase.gsub(/[^0-9a-z]/i, '_')
      end
      
      required_params = {
        :uid => more_params['uid'],
        :title => title,
        :og_description => description,
        :field_location => {:'0' => location},
        :taxonomy => vocabulary,
        :spaces_preset_og => type.downcase,
        :purl => {:value => purl_path}
      }    

      # APCIHACK - Fix non-required fields...
      more_params.merge!({
          :field_status => {:value => 'Active'},
          :field_group_mates => {:value => 'Group Mates'},
          :field_accept_amex => {:value => 'Accept'},
      })

      node_create title, 'group', nil, required_params.merge(more_params)
      #post 'groups', {:group => required_params.merge(more_params)}
      
    end

    def group_create_public(title, description, location, categories, more_params = {})
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

    def group_clone(target_uuid, origin_uuid)
      post 'groups/' + target_uuid + '/copy/' + origin_uuid
    end

    def group_get(group_uuid)
      get 'groups/' + group_uuid
    end
  end
end