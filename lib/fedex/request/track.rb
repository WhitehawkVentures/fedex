require 'fedex/request/base'

module Fedex
  module Request
    class Track < Base
      VERSION = 5
      
      def initialize(credentials, options={})
        super(credentials, options)
        @tracking_number, @tracking_type = options[:tracking_number], (options[:tracking_type] || "TRACKING_NUMBER_OR_DOORTAG")
        @tracking_number_unique_identifier = options[:tracking_number_unique_identifier]
      end
      
      # Sends post request to Fedex web service and parse the response
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          return response[:track_reply][:track_details]
        else
          puts api_response if @debug == true
          error_message = if response[:track_reply]
            [response[:track_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise TrackError, error_message
        end
      end

      private

      # add client detail
      def add_client_detail(xml)
        xml.ClientDetail{
          xml.AccountNumber @credentials.account_number
          xml.MeterNumber @credentials.meter
          xml.Localization{
            xml.LanguageCode "en"
            xml.LocaleCode "us"
          }
        }
      end

      # Add address
      def add_track_request(xml)
        xml.PackageIdentifier {
          xml.Value @tracking_number
          xml.Type @tracking_type
        }
        xml.TrackingNumberUniqueIdentifier @tracking_number_unique_identifier if @tracking_number_unique_identifier
        # xml.ShipDateRangeBegin
        # xml.ShipDateRangeEnd
        xml.ShipmentAccountNumber @credentials.account_number
        xml.IncludeDetailedScans true
        # xml.Destination
        # xml.IncludeDetailedScans
        # xml.PagingToken
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.TrackRequest(:xmlns => "http://fedex.com/ws/track/v5"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            # add_request_timestamp(xml)
            add_track_request(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'trck'
      end

      # Successful request
      def success?(response)
        response[:track_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:track_reply][:highest_severity])
      end

    end
  end
end
