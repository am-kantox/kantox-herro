# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kantox/herro/version'

Gem::Specification.new do |spec|
  spec.name          = 'kantox-herro'
  spec.version       = Kantox::Herro::VERSION
  spec.authors       = ['Kantox LTD']
  spec.email         = ['aleksei.matiushkin@kantox.com']

  spec.summary       = 'Handle errors in RoR with ease.'
  spec.description   = 'This gem provides the application-wide mechanism on handling errors over RoR applications. It takes care about handling, rethrowing, logging errors.'
  spec.homepage      = 'http://kantox.com'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    fail 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(/bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'

  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'awesome_print', '~> 1'
  spec.add_development_dependency 'pry-stack_explorer', '~> 0'
end
