require 'old_busted_fedex/helpers'

module OldBustedFedex
  class Credentials
    include Helpers
    attr_reader :key, :password, :account_number, :meter, :mode, :freight_account_number

    # In order to use OldBustedFedex rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.old_busted_fedex.com/us/developer/ OldBustedFedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - OldBustedFedex web service key
    # @param [String] password - OldBustedFedex password
    # @param [String] account_number - OldBustedFedex account_number
    # @param [String] meter - OldBustedFedex meter number
    # @param [String] mode - [development/production]
    #
    # return a OldBustedFedex::Credentials object
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
