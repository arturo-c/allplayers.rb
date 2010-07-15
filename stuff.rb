#!/usr/bin/ruby
require 'apci_rest'

#Turn this into a test!!
apci_session = ApcirClient.new('user','','vbox.allplayers.com')
#admin = REXML::Document.new(apci_session.get_user(1))
#admin = Hpricot.XML(apci_session.get_user(1))
admin = apci_session.get_user(1)
#puts admin.to_yaml
admin_hash = Hash.from_xml(admin)
puts admin_hash.to_yaml