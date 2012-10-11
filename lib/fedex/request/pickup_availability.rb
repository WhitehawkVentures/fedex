require 'fedex/request/base'

module Fedex
  module Request
    class PickupAvailability < Base
      VERSION = 5
      
      def initialize(credentials, options={})
        super(credentials, options)
        @date = options[:date]
      end
      
      # Sends post request to Fedex web service and parse the response
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        Rails.logger.info(build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          puts response.inspect
          return response[:pickup_availability_reply]
        else
          puts api_response
          error_message = if response[:pickup_availability_reply]
            [response[:pickup_availability_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise PickUpError, error_message
        end
      end

      private
      
      def add_pickup_address(xml)
        xml.PickupAddress {
          Array(@shipper[:address]).take(2).each do |address_line|
            xml.StreetLines address_line
          end
          xml.City @shipper[:city]
          xml.StateOrProvinceCode @shipper[:state]
          xml.PostalCode @shipper[:postal_code]
          xml.CountryCode @shipper[:country_code]
        }
        xml.PickupRequestType "FUTURE_DAY"
        xml.DispatchDate @date.to_date.strftime("%F")
        xml.NumberOfBusinessDays 1
        xml.PackageReadyTime @date.strftime("%T")
        xml.CustomerCloseTime "17:00:00"
        xml.Carriers "FDXG"
      end
      
      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.PickupAvailabilityRequest(:xmlns => "http://fedex.com/ws/pickup/v5"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_pickup_address(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'disp'
      end

      # Successful request
      def success?(response)
        response[:pickup_availability_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:pickup_availability_reply][:highest_severity])
      end

    end
  end
end