require 'fed_ex/credentials'
require 'fed_ex/request/label'
require 'fed_ex/request/delete_shipment'
require 'fed_ex/request/rate'
require 'fed_ex/request/address_validation'
require 'fed_ex/request/track'
require 'fed_ex/request/pickup'
require 'fed_ex/request/cancel_pickup'
require 'fed_ex/request/pickup_availability'
require 'fed_ex/request/etd'

module FedEx
  class Shipment

    # In order to use FedEx rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.fed_ex.com/us/developer/ FedEx Developer Center} for more information about how to obtain your keys.
    # @param [String] key - FedEx web service key
    # @param [String] password - FedEx password
    # @param [String] account_number - FedEx account_number
    # @param [String] meter - FedEx meter number
    # @param [String] mode - [development/production]
    #
    # return a FedEx::Shipment object
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fed_ex service type, to view a complete list of services FedEx::Shipment::SERVICE_TYPES
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
    # @param [String] service_type, A valid fed_ex service type, to view a complete list of services FedEx::Shipment::SERVICE_TYPES
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
