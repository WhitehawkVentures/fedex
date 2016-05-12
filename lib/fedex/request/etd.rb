require 'fedex/request/base'

module Fedex
  module Request
    class EtdUpload < Base
      VERSION = 1
      
      def initialize(credentials, options={})
        super(credentials, options)
        @image = options[:image]
        @origin = options[:origin]
        @destination = options[:destination]
      end
      
      # Sends post request to Fedex web service and parse the response
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        Rails.logger.info(build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          puts response.inspect if @debug == true
          return response[:upload_documents_reply]
        else
          puts api_response if @debug == true
          error_message = if response[:upload_documents_reply]
            [response[:upload_documents_reply][:notifications]].flatten.first[:message]
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
          xml.UploadDocumentsRequest(:xmlns => "http://fedex.com/ws/uploaddocument/v1"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            xml.OriginCountryCode @origin
            xml.DestinationCountryCode @destination
            xml.Documents {
              xml.DocumentType "COMMERCIAL_INVOICE"
              xml.FileName "ci.pdf"
              xml.DocumentContent @image
            }
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'cdus'
      end

      # Successful request
      def success?(response)
        response[:upload_documents_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:upload_documents_reply][:highest_severity])
      end

    end
  end
end