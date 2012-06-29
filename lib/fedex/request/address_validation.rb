require 'fedex/request/base'

module Fedex
  module Request
    class AddressValidation < Base
      VERSION = 2
      
      def initialize(credentials, options={})
        requires!(options, :recipient)
        super(credentials, options)
      end
      
      # Sends post request to Fedex web service and parse the response
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          # puts response.inspect
          return response[:address_validation_reply][:address_results][:proposed_address_details]
        else
          puts api_response
          error_message = if response[:address_validation_reply]
            [response[:address_validation_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise AddressValidationError, error_message
        end
      end

      private

      # Add address
      def add_address(xml)
        xml.AddressesToValidate{
          xml.Address {
            Array(@recipient[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @recipient[:city]
            xml.StateOrProvinceCode @recipient[:state]
            xml.PostalCode @recipient[:postal_code]
            xml.CountryCode @recipient[:country_code]
          }
        }
      end
      
      def add_options(xml)
        xml.Options{
          xml.CheckResidentialStatus true
        }
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.AddressValidationRequest(:xmlns => "http://fedex.com/ws/addressvalidation/v2"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_request_timestamp(xml)
            add_options(xml)
            add_address(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'aval'
      end

      # Successful request
      def success?(response)
        response[:address_validation_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:address_validation_reply][:highest_severity])
      end

    end
  end
end