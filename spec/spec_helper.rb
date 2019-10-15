require 'rspec'
require 'old_busted_fedex'
require 'support/vcr'

def fedex_credentials
  @fedex_credentials ||= YAML.load(File.read("#{File.dirname(__FILE__)}/config/fedex_credentials.yml"))["development"]
end
