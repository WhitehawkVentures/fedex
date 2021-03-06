require 'fedex/credentials'
require 'fedex/request/label'
require 'fedex/request/delete_shipment'
require 'fedex/request/rate'
require 'fedex/request/address_validation'
require 'fedex/request/track'
require 'fedex/request/pickup'
require 'fedex/request/cancel_pickup'
require 'fedex/request/pickup_availability'
require 'fedex/request/etd'

module Fedex
  class Shipment

    # In order to use Fedex rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - Fedex web service key
    # @param [String] password - Fedex password
    # @param [String] account_number - Fedex account_number
    # @param [String] meter - Fedex meter number
    # @param [String] mode - [development/production]
    #
    # return a Fedex::Shipment object
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
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
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
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