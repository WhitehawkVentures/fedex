require 'fedex/request/base'

module Fedex
  module Request
    class DeleteShipment < Base
      VERSION = 10
      
      def initialize(credentials, options={})
        super(credentials, options)
        @tracking_number = options[:tracking_number]
      end
      
      # Sends post request to Fedex web service and parse the response
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        Rails.logger.info(build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          puts response.inspect
          return true
        else
          puts api_response
          error_message = if response[:shipment_reply]
            [response[:shipment_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise PickUpError, error_message
        end
      end

      private
      
      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.DeleteShipmentRequest(:xmlns => "http://fedex.com/ws/ship/v10"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            xml.TrackingId {
              xml.TrackingIdType "FEDEX"
              xml.TrackingNumber @tracking_number
            } 
            xml.DeletionControl "DELETE_ALL_PACKAGES"
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'ship'
      end

      # Successful request
      def success?(response)
        response[:shipment_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:shipment_reply][:highest_severity])
      end

    end
  end
end