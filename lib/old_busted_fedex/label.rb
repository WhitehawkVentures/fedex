module OldBustedFedex
  class Label
    attr_accessor :options

    # Initialize OldBustedFedex::Label Object
    # @param [Hash] options
    def initialize(options = {})
      @options = options
    end
  end
end
