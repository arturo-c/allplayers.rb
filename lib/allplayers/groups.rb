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

      #node_create title, 'group', nil, required_params.merge(more_params)
      post 'groups', required_params, {:params => more_params}
      
    end
  end
end