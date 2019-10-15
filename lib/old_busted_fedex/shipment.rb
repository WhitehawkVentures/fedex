require 'old_busted_fedex/credentials'
require 'old_busted_fedex/request/label'
require 'old_busted_fedex/request/delete_shipment'
require 'old_busted_fedex/request/rate'
require 'old_busted_fedex/request/address_validation'
require 'old_busted_fedex/request/track'
require 'old_busted_fedex/request/pickup'
require 'old_busted_fedex/request/cancel_pickup'
require 'old_busted_fedex/request/pickup_availability'
require 'old_busted_fedex/request/etd'

module OldBustedFedex
  class Shipment

    # In order to use OldBustedFedex rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.old_busted_fedex.com/us/developer/ OldBustedFedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - OldBustedFedex web service key
    # @param [String] password - OldBustedFedex password
    # @param [String] account_number - OldBustedFedex account_number
    # @param [String] meter - OldBustedFedex meter number
    # @param [String] mode - [development/production]
    #
    # return a OldBustedFedex::Shipment object
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid old_busted_fedex service type, to view a complete list of services OldBustedFedex::Shipment::SERVICE_TYPES
    # @param [String] filename, A location where the label will be saved
    def label(options = {})
      Request::Label.new(@credentials, options).process_request
    end
    
    def delete_shipment(options = {})
      Request::DeleteShipment.new(@credentials, options).process_request
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid old_busted_fedex service type, to view a complete list of services OldBustedFedex::Shipment::SERVICE_TYPES
    def rate(options = {})
      Request::Rate.new(@credentials, options).process_request
    end
    
    def track(options = {})
      Request::Track.new(@credentials, options).process_request
    end
    
    def pickup(options = {})
      Request::Pickup.new(@credentials, options).process_request
    end
    
    def cancel_pickup(options = {})
      Request::CancelPickup.new(@credentials, options).process_request
    end
    
    def get_pickup_availability(options = {})
      Request::PickupAvailability.new(@credentials, options).process_request
    end
    
    def verify_residential(options = {})
      Request::AddressValidation.new(@credentials, options).process_request
    end
    
    def upload_document(options = {})
      Request::EtdUpload.new(@credentials, options).process_request
    end

  end
end
