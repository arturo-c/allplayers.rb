# encoding: utf-8
Gem::Specification.new do |spec|
  spec.add_dependency 'rake', ['>= 10.0.3']
  spec.add_dependency 'rack', ['>= 1.4.0']
  spec.add_dependency 'rest-client', ['>= 1.6.7']
  spec.add_dependency 'xml-simple', ['>= 1.1.1']
  spec.add_dependency 'json', ['1.7.6']
  spec.add_dependency 'oauth', ['>= 0.4.7']
  spec.add_development_dependency 'rspec'
  spec.authors = ["AllPlayers.com"]
  spec.description = %q{A Ruby interface to the AllPlayers API.}
  spec.email = ['support@allplayers.com']
  spec.files = %w(README.md allplayers.gemspec)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*")
  spec.homepage = 'http://www.allplayers.com/'
  spec.licenses = ['MIT']
  spec.name = 'allplayers'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.summary = spec.description
  spec.test_files = Dir.glob("spec/**/*")
  spec.version = '0.1.2'
end
