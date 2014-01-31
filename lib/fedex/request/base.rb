require 'httparty'
require 'nokogiri'
require 'fedex/helpers'
require 'fedex/rate'

module Fedex
  module Request
    class Base
      include Helpers
      include HTTParty
      format :xml
      # If true the rate method will return the complete response from the Fedex Web Service
      attr_accessor :debug
      # Fedex Text URL
      TEST_URL = "https://gatewaybeta.fedex.com:443/xml/"

      # Fedex Production URL
      PRODUCTION_URL = "https://gateway.fedex.com:443/xml/"

      # Fedex Version number for the Fedex service used
      VERSION = 10

      # List of available Service Types
      SERVICE_TYPES = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY FEDEX_FREIGHT_PRIORITY FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY INTERNATIONAL_ECONOMY INTERNATIONAL_ECONOMY_FREIGHT INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY INTERNATIONAL_PRIORITY_FREIGHT PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT)

      # List of available Packaging Type
      PACKAGING_TYPES = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING)

      # List of available DropOffTypes
      DROP_OFF_TYPES = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION)

      # Clearance Brokerage Type
      CLEARANCE_BROKERAGE_TYPE = %w(BROKER_INCLUSIVE BROKER_INCLUSIVE_NON_RESIDENT_IMPORTER BROKER_SELECT BROKER_SELECT_NON_RESIDENT_IMPORTER BROKER_UNASSIGNED)

      # Recipient Custom ID Type
      RECIPIENT_CUSTOM_ID_TYPE = %w(COMPANY INDIVIDUAL PASSPORT)

      # In order to use Fedex rates API you must first apply for a developer(and later production keys),
      # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
      # @param [String] key - Fedex web service key
      # @param [String] password - Fedex password
      # @param [String] account_number - Fedex account_number
      # @param [String] meter - Fedex meter number
      # @param [String] mode - [development/production]
      #
      # return a Fedex::Request::Base object
      def initialize(credentials, options={})
        # requires!(options, :shipper, :recipient, :packages, :service_type)
        @credentials = credentials
        @shipper, @recipient, @packages, @service_type, @customs_clearance, @debug, @label_type, @printed_label_origin = options[:shipper], options[:recipient], options[:packages], options[:service_type], options[:customs_clearance], options[:debug], options[:label_type], options[:printed_label_origin]
        @freight_address, @freight_contact = options[:freight_address], options[:freight_contact]
        @description, @declared_value = options[:description], options[:declared_value]
        @special_services = options[:special_services]
        @shipping_options =  options[:shipping_options] ||={}
      end

      # Sends post request to Fedex web service and parse the response.
      # Implemented by each subclass
      def process_request
        raise NotImplementedError, "Override process_request in subclass"
      end

      private
      # Add web authentication detail information(key and password) to xml request
      def add_web_authentication_detail(xml)
        xml.WebAuthenticationDetail{
          xml.UserCredential{
            xml.Key @credentials.key
            xml.Password @credentials.password
          }
        }
      end

      # Add Client Detail information(account_number and meter_number) to xml request
      def add_client_detail(xml)
        xml.ClientDetail{
          xml.AccountNumber @credentials.account_number
          xml.MeterNumber @credentials.meter
        }
      end

      # Add Version to xml request, using the latest version V10 Sept/2011
      def add_version(xml)
        xml.Version{
          xml.ServiceId service_id
          xml.Major self.class::VERSION
          xml.Intermediate 0
          xml.Minor 0
        }
      end

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      # Add shipper to xml request
      def add_shipper(xml)
        xml.Shipper{
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
      end
      
      # Add printed label origin to xml request
      def add_printed_label_origin(xml)
        xml.PrintedLabelOrigin{
          xml.Contact{
            xml.PersonName @printed_label_origin[:name]
            xml.CompanyName @printed_label_origin[:company]
            xml.PhoneNumber @printed_label_origin[:phone_number]
          }
          xml.Address {
            Array(@printed_label_origin[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @printed_label_origin[:city]
            xml.StateOrProvinceCode @printed_label_origin[:state]
            xml.PostalCode @printed_label_origin[:postal_code]
            xml.CountryCode @printed_label_origin[:country_code]
          }
        }
      end

      # Add recipient to xml request
      def add_recipient(xml)
        xml.Recipient{
          xml.Contact{
            xml.PersonName @recipient[:name]
            xml.CompanyName @recipient[:company]
            xml.PhoneNumber @recipient[:phone_number]
          }
          xml.Address {
            Array(@recipient[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @recipient[:city]
            xml.StateOrProvinceCode @recipient[:state]
            xml.PostalCode @recipient[:postal_code]
            xml.CountryCode @recipient[:country_code]
            xml.Residential @recipient[:residential]
          }
        }
      end

      # Add shipping charges to xml request
      def add_shipping_charges_payment(xml)
        xml.ShippingChargesPayment{
          xml.PaymentType "SENDER"
          xml.Payor{
            xml.AccountNumber @credentials.account_number
            xml.CountryCode @shipper[:country_code]
          }
        }
      end

      # Add packages to xml request
      def add_packages(xml)
        xml.MasterTrackingId {
          xml.TrackingNumber @mps_details[:master_tracking_id]
        } if @mps_details && @mps_details[:master_tracking_id]
        if ["FEDEX_FREIGHT_ECONOMY", "FEDEX_FREIGHT_PRIORITY"].include?(@service_type)
          packages = [@packages.first]
        else
          packages = @packages
        end
        package_count = packages.size
        xml.PackageCount (@mps_details && @mps_details[:package_count]) || 1
        packages.each do |package|
          xml.RequestedPackageLineItems{
            xml.SequenceNumber @mps_details[:sequence_number] if @mps_details
            xml.GroupPackageCount 1
            xml.InsuredValue {
              xml.Currency "USD"
              xml.Amount package[:value]
            } if package[:value] && !["FEDEX_FREIGHT_ECONOMY", "FEDEX_FREIGHT_PRIORITY"].include?(@service_type)
            xml.Weight{
              xml.Units package[:weight][:units]
              xml.Value package[:weight][:value]
            }
            xml.Dimensions {
              xml.Length package[:dimensions][:length].to_i
              xml.Width package[:dimensions][:width].to_i
              xml.Height package[:dimensions][:height].to_i
              xml.Units package[:dimensions][:units]
            } if package[:dimensions]
            xml.CustomerReferences {
              xml.CustomerReferenceType "CUSTOMER_REFERENCE"
              xml.Value package[:reference]
            }
          }
        end
      end
      
      def add_freight_shipment_detail(xml)
        xml.FreightShipmentDetail {
          xml.FedExFreightAccountNumber @credentials.freight_account_number
          xml.FedExFreightBillingContactAndAddress {
            xml.Contact{
              xml.PersonName @freight_contact[:person_name]
              xml.Title @freight_contact[:title]
              xml.CompanyName @freight_contact[:company_name]
              xml.PhoneNumber @freight_contact[:phone_number]
            }
            xml.Address {
              Array(@freight_address[:address]).take(2).each do |address_line|
                xml.StreetLines address_line
              end
              xml.City @freight_address[:city]
              xml.StateOrProvinceCode @freight_address[:state]
              xml.PostalCode @freight_address[:postal_code]
              xml.CountryCode @freight_address[:country_code]
            }
          }
          # xml.Role @recipient[:company] == "TouchOfModern" ? "SHIPPER" : "THIRD_PARTY"
          # xml.PaymentType @recipient[:company] == "TouchOfModern" ? "COLLECT" : "PREPAID"
          xml.Role @shipping_options[:role] || (@recipient[:company] == "TouchOfModern" ? "SHIPPER" : "THIRD_PARTY")
          xml.PaymentType @shipping_options[:payment] || (@recipient[:company] == "TouchOfModern" ? "COLLECT" : "PREPAID")
          xml.CollectTermsType "STANDARD"
          xml.TotalHandlingUnits 1
          xml.ClientDiscountPercent 0
          xml.PalletWeight {
            xml.Units @packages.first[:weight][:units]
            xml.Value @packages.first[:weight][:value]
          }
          @packages.each do |package|
            xml.LineItems {
              xml.FreightClass 'CLASS_085'
              xml.ClassProvidedByCustomer false
              xml.HandlingUnits 1
              xml.Packaging 'PALLET'
              xml.Pieces package[:qty] || 1
              xml.PurchaseOrderNumber package[:reference]
              xml.Description package[:description] || "Furniture"
              xml.Weight {
                xml.Units package[:weight][:units]
                xml.Value package[:weight][:value]
              }
              xml.Dimensions {
                xml.Length package[:dimensions][:length].to_i
                xml.Width package[:dimensions][:width].to_i
                xml.Height package[:dimensions][:height].to_i
                xml.Units package[:dimensions][:units]
              } if package[:dimensions]
            }
          end
        }
      end
      
      def add_package_detail(xml)
        xml.PackageCount 1
        xml.PackageDetail 'INDIVIDUAL_PACKAGES'
      end

      # Add customs clearance(for international shipments)
      def add_customs_clearance(xml)
        xml.CustomsClearanceDetail{
          customs_to_xml(xml, @customs_clearance)
        }
      end
      
      def add_other(xml, content)
        customs_to_xml(xml, content)
      end
      
      def add_request_timestamp(xml)
        xml.RequestTimestamp Time.now.xmlschema
      end

      # Fedex Web Service Api
      def api_url
        ["production", "staging"].include?(@credentials.mode) ? PRODUCTION_URL : TEST_URL
      end

      # Build xml Fedex Web Service request
      # Implemented by each subclass
      def build_xml
        raise NotImplementedError, "Override build_xml in subclass"
      end

      # Build nodes dinamically from the provided customs clearance hash
      def customs_to_xml(xml, hash)
        hash.each do |key, value|
          if value.is_a?(Hash)
            xml.send "#{camelize(key.to_s)}" do |x|
              customs_to_xml(x, value)
            end
          elsif value.is_a?(Array)
            node = key
            value.each do |v|
              xml.send "#{camelize(node.to_s)}" do |x|
                customs_to_xml(x, v)
              end
            end
          else
            xml.send "#{camelize(key.to_s)}", value unless key.is_a?(Hash)
          end
        end
      end

      # Parse response, convert keys to underscore symbols
      def parse_response(response)
        response = sanitize_response_keys(response)
      end

      # Recursively sanitizes the response object by clenaing up any hash keys.
      def sanitize_response_keys(response)
        if response.is_a?(Hash)
          response.inject({}) { |result, (key, value)| result[underscorize(key).to_sym] = sanitize_response_keys(value); result }
        elsif response.is_a?(Array)
          response.collect { |result| sanitize_response_keys(result) }
        else
          response
        end
      end

      def service_id
        'crs'
      end

      # Use GROUND_HOME_DELIVERY for shipments going to a residential address within the US.
      def service_type
        if ["HI","AK"].include?(@recipient[:state]) and @recipient[:country_code] =~ /US/i and @shipper[:country_code] =~ /US/i
          "FEDEX_2_DAY"
        else
          if @recipient[:residential].to_s =~ /true/i and @service_type =~ /GROUND/i and @recipient[:country_code] =~ /US/i and @shipper[:country_code] =~ /US/i
            if @packages.first[:weight][:value] < 70
              "GROUND_HOME_DELIVERY"
            else
              @service_type
            end
          else
            @service_type
          end
        end
      end

      # Successful request
      def success?(response)
        (!response[:rate_reply].nil? and %w{SUCCESS WARNING NOTE}.include? response[:rate_reply][:highest_severity])
      end

    end
  end
end