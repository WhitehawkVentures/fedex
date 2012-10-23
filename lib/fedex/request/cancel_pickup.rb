require 'fedex/request/base'

module Fedex
  module Request
    class CancelPickup < Base
      VERSION = 5
      
      def initialize(credentials, options={})
        super(credentials, options)
        @number = options[:number]
        @date = options[:date]
        @carrier = options[:carrier]
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
          error_message = if response[:cancel_pickup_reply]
            [response[:cancel_pickup_reply][:notifications]].flatten.first[:message]
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
          xml.CancelPickupRequest(:xmlns => "http://fedex.com/ws/pickup/v5"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            xml.CarrierCode @carrier || "FDXG"
            xml.PickupConfirmationNumber @number
            xml.ScheduledDate @date.strftime("%F")
            xml.Remarks "Cancelling..."
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'disp'
      end

      # Successful request
      def success?(response)
        response[:cancel_pickup_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:cancel_pickup_reply][:highest_severity])
      end

    end
  end
end