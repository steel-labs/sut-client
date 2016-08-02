# coding: utf-8
require 'SignUpToClient/version'

Gem::Specification.new do |spec|
  spec.name          = 'SignUpToClient'
  spec.version       = SignUpToClient::VERSION
  spec.authors       = ['Giovanni Derks', 'Raffaele Abramini']
  spec.email         = ['giovanni.derks@steellondon.com', 'raffaele.abramini@steellondon.com']

  spec.summary       = 'Sign Up To client'
  spec.homepage      = 'https://github.com/steel-labs/sut-client'
  spec.license       = 'MIT'
  spec.files         = ['lib/SignUpToClient.rb']

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://github.com/steel-labs/sut-client'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.add_dependency 'httparty'
  spec.add_dependency 'uuidtools'
end
