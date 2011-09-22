require 'helper'

describe AllPlayers::Client do
  describe "File" do
    before :all do
      $filelist = $apci_session.file_list({:filemime => 'image/jpeg'})
      $fid = $filelist['item'].last['fid']
    end

    it "should be retrievable. (get)" do
      fid = $fid.to_i
      file = $apci_session.file_get(fid, true)

      file['fid'].to_i.should == fid
      file['contents'].should_not == nil

      web_file = open('https://' + $apci_rest_test_host + '/' + file['filepath']) {|f| f.read }
      web_file.should == file['contents']
    end

    it "should be created properly." do
      remote_file = open('http://www.google.com/images/logos/ps_logo2.png') {|f| f.read }
      file_data = {:filename => 'googlelogo.png', :file => remote_file}
      response = $apci_session.file_create(file_data)
      response['fid'].should_not == nil

      file = $apci_session.file_get(response['fid'], true)
      response['fid'].should_not == nil
      file['fid'].should == response['fid']
      file['contents'].should_not == nil
      remote_file.should == file['contents']
      web_file = open('https://' + $apci_rest_test_host + '/' + file['filepath']) {|f| f.read }
      web_file.should == file['contents']
    end
  end
end
