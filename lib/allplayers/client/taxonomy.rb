module AllPlayers
  module Taxonomy
    def taxonomy_vocabulary_list(filters)
      #[GET] {endpoint}/vocabulary (?fields[]=fieldname&vid=value)
      get 'vocabulary', {:parameters => filters}
    end

    def taxonomy_term_list(filters)
      #[GET] {endpoint}/term (?fields[]=fieldname&tid=value)
      get 'term' , {:parameters => filters}
    end
  end
end
