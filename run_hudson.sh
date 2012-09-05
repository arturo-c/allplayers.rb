export APCI_REST_TEST_USER=${MERCURY_LOGIN_U}
export APCI_REST_TEST_PASS=${MERCURY_LOGIN_P}
bundle install --path vendor/bundle
#Run ruby client testunit
bundle exec rake ci:setup:testunit test CI_REPORTS=results
#Run ruby client rspec tests
bundle exec rake spec CI_REPORTS=results
