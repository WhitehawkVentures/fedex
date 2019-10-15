# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fedex/version"

Gem::Specification.new do |s|
  s.name        = "fed_ex"
  s.version     = FedEx::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jazmin Schroeder"]
  s.email       = ["jazminschroeder@gmail.com"]
  s.homepage    = "https://github.com/WhitehawkVentures/fedex"
  s.summary     = %q{Old Busted Fedex Rate Webservice}
  s.description = %q{Old Busted Ruby Library to use Fedex Web Services(version 10)}

  s.rubyforge_project = "fed_ex"

  s.add_dependency 'httparty',            '~> 0.11.0'
  s.add_dependency 'nokogiri',            '~> 1.6'

  s.add_development_dependency "rspec",   '~> 2.11.0'
  s.add_development_dependency 'vcr',     '~> 2.0.0'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'pry'
  # s.add_runtime_dependency "rest-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
