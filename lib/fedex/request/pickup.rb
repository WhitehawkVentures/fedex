require 'fedex/request/base'

module Fedex
  module Request
    class Pickup < Base
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
          return response[:create_pickup_reply][:pickup_confirmation_number]
        else
          puts api_response
          error_message = if response[:create_pickup_reply]
            [response[:create_pickup_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise PickUpError, error_message
        end
      end

      private
      
      def add_origin_detail(xml)
        xml.OriginDetail {
          xml.UseAccountAddress false
          xml.PickupLocation {
            xml.Contact{
              xml.PersonName @shipper[:name]
              xml.CompanyName @shipper[:company]
              xml.PhoneNumber @shipper[:phone_number]
            }
            xml.Address {
              Array(@shipper[:address]).take(2).each do |address_line|
                xml.StreetLines address_line
              end
              xml.City @shipper[:city]
              xml.StateOrProvinceCode @shipper[:state]
              xml.PostalCode @shipper[:postal_code]
              xml.CountryCode @shipper[:country_code]
            }
          }
          xml.PackageLocation "NONE"
          xml.ReadyTimestamp @date.xmlschema
          xml.CompanyCloseTime "17:00:00"
        }
      end
      
      def add_package_details(xml)
        xml.PackageCount @packages.count
        xml.TotalWeight {
          xml.Units "LB"
          xml.Value @packages.sum{|n| n[:weight][:value]}
        }
        xml.CarrierCode "FDXG"
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.CreatePickupRequest(:xmlns => "http://fedex.com/ws/pickup/v5"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_origin_detail(xml)
            add_package_details(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'disp'
      end

      # Successful request
      def success?(response)
        response[:create_pickup_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:create_pickup_reply][:highest_severity])
      end

    end
  end
end