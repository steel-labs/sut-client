# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'sign_up_to_client/version'

Gem::Specification.new do |s|
  s.name          = 'sign_up_to_client'
  s.version       = SignUpToClient::VERSION
  s.authors       = ['Giovanni Derks', 'Raffaele Abramini']
  s.email         = ['giovanni.derks@steellondon.com', 'raffaele.abramini@steellondon.com']

  s.summary       = 'Sign Up To client'
  s.homepage      = 'https://github.com/steel-labs/sut-client'
  s.license       = 'MIT'
  s.files         = Dir['LICENSE', 'lib/**/*']
  s.require_path  = 'lib'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = 'https://github.com/steel-labs/sut-client'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  s.add_dependency 'httparty', '~> 0.14.0'
  s.add_dependency 'uuidtools', '~> 2.1', '>= 2.1.5'
end
