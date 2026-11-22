# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class SkipUsedPorts
        def initialize(skip_used_ports:)
          @skip_used_ports = skip_used_ports
        end

        def valid? = [true, false].include?(skip_used_ports)

        def message = "skip_used_ports must be true or false."

        private

        attr_reader :skip_used_ports
      end
    end
  end
end
