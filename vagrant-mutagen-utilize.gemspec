# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-mutagen-utilize/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-mutagen-utilize'
  spec.version       = VagrantPlugins::Mutagen::VERSION
  spec.authors       = ['Ryu Sato']
  spec.email         = ['ryu@weseek.co.jp']
  spec.description   = %q{Enables Vagrant to utilize mutagen for project sync}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/ryu-sato/vagrant-mutagen-utilize'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
