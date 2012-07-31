# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name         = "higcm"
  s.version      = "0.0.3"
  s.authors      = ["hifrank"]
  s.email        = "frank_chen@htc.com"
  s.homepage     = "https://github.com/hifrank/higcm"
  s.summary      = "ruby wrapper for GCM google cloud messaging."
  s.description  = %q{ruby wrapper for GCM google cloud messaging.}
  #s.extensions   = [""]
  s.files        = (`git ls-files ext lib spec`.split("\n")) + [
                     'README.md',
                     'Gemfile',
                     'Gemfile.lock',
                     'Rakefile',
                     'higcm.gemspec'
                   ]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_runtime_dependency 'typhoeus', ['~> 0.3.3']
  s.add_development_dependency 'rspec', ["~> 2.6"]
  s.add_development_dependency 'json', [">= 0"]
  s.add_development_dependency 'rake', [">= 0"]
end

