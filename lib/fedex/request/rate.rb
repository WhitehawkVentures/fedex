require 'fedex/request/base'

module Fedex
  module Request
    class Rate < Base
      VERSION = 18

      def initialize(credentials, options={})
        requires!(options, :shipper, :recipient, :packages)
        Rails.logger.info(options.inspect)
        @edt_request_type = options[:edt_request_type]
        super(credentials, options)
      end
      
      # Sends post request to Fedex web service and parse the response, a Rate object is created if the response is successful
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        Rails.logger.info(build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          rate_details = response[:rate_reply][:rate_reply_details]
          # Fedex::Rate.new(rate_details)
        else
          error_message = if response[:rate_reply]
            [response[:rate_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.ReturnTransitAndCommit true
        xml.RequestedShipment{
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type if service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_smart_post_detail(xml) if @smart_post_detail
          add_other(xml, @special_services) if @special_services
          add_customs_clearance(xml) if @customs_clearance
          add_freight_shipment_detail(xml) if @freight_address
          xml.RateRequestTypes "NONE"
          xml.EdtRequestType "ALL" if @edt_request_type
          add_packages(xml) unless @freight_address
        }
      end

      def add_smart_post_detail(xml)
        xml.SmartPostDetail{
          hash_to_xml(xml, @smart_post_detail)
        }
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.RateRequest(:xmlns => "http://fedex.com/ws/rate/v#{VERSION}"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_shipment(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'crs'
      end

      # Successful request
      def success?(response)
        response[:rate_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:rate_reply][:highest_severity])
      end

    end
  end
end