require 'fed_ex/helpers'

module FedEx
  class Credentials
    include Helpers
    attr_reader :key, :password, :account_number, :meter, :mode, :freight_account_number

    # In order to use FedEx rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.fed_ex.com/us/developer/ FedEx Developer Center} for more information about how to obtain your keys.
    # @param [String] key - FedEx web service key
    # @param [String] password - FedEx password
    # @param [String] account_number - FedEx account_number
    # @param [String] meter - FedEx meter number
    # @param [String] mode - [development/production]
    #
    # return a FedEx::Credentials object
    def initialize(options={})
      requires!(options, :key, :password, :account_number, :meter, :mode)
      @key = options[:key]
      @password = options[:password]
      @account_number = options[:account_number]
      @meter = options[:meter]
      @mode = options[:mode]
      @freight_account_number = options[:freight_account]
    end
  end
end
