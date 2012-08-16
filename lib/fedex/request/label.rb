require 'fedex/request/base'
require 'fedex/label'
require 'fileutils'

module Fedex
  module Request
    class Label < Base
      def initialize(credentials, options={})
        requires!(options, :shipper, :recipient, :packages, :service_type)
        super(credentials, options)
      end

      # Sends post request to Fedex web service and parse the response.
      # A Fedex::Label object is created if the response is successful and
      # a PDF file is created with the label at the specified location.
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        Rails.logger.info(build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          Rails.logger.info(response.inspect)
          # create_pdf(label_details)
          if service_type.include?("FREIGHT")
            { :encoded_image => response[:process_shipment_reply][:completed_shipment_detail][:shipment_documents].first[:parts][:image], :encoded_bol => response[:process_shipment_reply][:completed_shipment_detail][:shipment_documents].second[:parts][:image], :tracking_number => response[:process_shipment_reply][:completed_shipment_detail][:master_tracking_id][:tracking_number] }
          else
            { :encoded_image => response[:process_shipment_reply][:completed_shipment_detail][:completed_package_details][:label][:parts][:image], :tracking_number => response[:process_shipment_reply][:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number] }
          end
        else
          Rails.logger.info(response.inspect)
          error_message = if response[:process_shipment_reply]
            [response[:process_shipment_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.ShipTimestamp Time.now.utc.iso8601(2)
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance
          if service_type.include?("FREIGHT")
            add_freight_shipment_detail(xml)
          end
          xml.LabelSpecification {
            xml.LabelFormatType service_type.include?("FREIGHT") ? "VICS_BILL_OF_LADING" : "COMMON2D"
            xml.ImageType service_type.include?("FREIGHT") ? "PDF" : @label_type
            xml.LabelStockType service_type.include?("FREIGHT") ? "PAPER_LETTER" : (@label_type == "EPL2" ? "STOCK_4X6" : "PAPER_8.5X11_TOP_HALF_LABEL")
            add_printed_label_origin(xml) if @printed_label_origin
          }
          if service_type.include?("FREIGHT")
            xml.ShippingDocumentSpecification {
              xml.ShippingDocumentTypes "FREIGHT_ADDRESS_LABEL"
              xml.FreightAddressLabelDetail {
                xml.Format {
                  xml.ImageType @label_type
                  xml.StockType @label_type == "EPL2" ? "STOCK_4X6" : "PAPER_4X6"
                  xml.ProvideInstructions true
                }
              }
            }
          end
          xml.RateRequestTypes "ACCOUNT"
          # unless service_type.include?("FREIGHT")
            add_packages(xml)
          # else
            # add_package_detail(xml)
          # end
          
        }
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.ProcessShipmentRequest(:xmlns => "http://fedex.com/ws/ship/v10"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_shipment(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service_id
        'ship'
      end

      # Successful request
      def success?(response)
        response[:process_shipment_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:process_shipment_reply][:highest_severity])
      end

    end
  end
end