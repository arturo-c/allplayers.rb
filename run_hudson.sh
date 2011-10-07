export APCI_REST_TEST_USER=${MERCURY_LOGIN_U}
export APCI_REST_TEST_PASS=${MERCURY_LOGIN_P}
export SSL_CHECK=1
rake ci:setup:testunit test CI_REPORTS=results
rake spec CI_REPORTS=results
