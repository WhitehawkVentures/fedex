module FedEx
  class Label
    attr_accessor :options

    # Initialize FedEx::Label Object
    # @param [Hash] options
    def initialize(options = {})
      @options = options
    end
  end
end
