require 'helper'

describe AllPlayers::Client do
  describe "Taxonomy" do
    it "should be able to list vocabulary." do
      vocab = $apci_session.taxonomy_vocabulary_list({:module => 'features_group_category'})
      vocab['item'].first['module'].should == "features_group_category"
    end
    it "should be able to list terms." do
      term = $apci_session.taxonomy_term_list({:name => 'Other'})
      term['item'].first['name'].should == "Other"
    end
  end
end
