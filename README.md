allplayers.rb
=============

AllPlayers.com ruby client  https://www.allplayers.com

AllPlayer.com, Inc. Ruby client for importing users, groups, events, etc via
REST API.

Requires Ruby + Rubygems and the following:

sudo apt-get install ruby libopenssl-ruby

# nokogiri requirements
sudo apt-get install libxslt-dev libxml2-dev

# install bundler
sudo gem install bundler

# run bundler
bundle install

export APCI_REST_TEST_HOST=host.allplayers.com
export APCI_REST_TEST_USER=user
export APCI_REST_TEST_PASS=password

then 'rake test'.

# execute an import
cd lib
bundle exec 'gdoc_to_apci.rb --gdoc-mail USERNAME@allplayers.com admin@www.a.USERNAME.allplayers.com'

