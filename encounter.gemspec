lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include? lib

require 'encounter/version'

Gem::Specification.new do |spec|
  spec.name = 'encounter'
  spec.version = Encounter::VERSION
  spec.authors = ['Eugene Lapeko']
  spec.email   = ['eugene@lapeko.info']
  spec.summary = 'A gem to interact with http://en.cx/ game network.'
  spec.homepage = ''
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0")
  spec.test_files = `git ls-files -z -- {test,spec,features}/*`.split("\x0")

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faraday', '~> 0.9'
  spec.add_runtime_dependency 'faraday-cookie_jar', '>= 0.0.6'
  spec.add_runtime_dependency 'faraday_middleware', '~> 0.10'
  spec.add_runtime_dependency 'nokogiri', '~> 1.6'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 0.50'
  spec.add_development_dependency 'sinatra', '~> 1.4'
  spec.add_development_dependency 'webmock', '~> 1.22'
end
