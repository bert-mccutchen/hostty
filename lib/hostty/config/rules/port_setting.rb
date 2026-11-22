# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class PortSetting
        def initialize(name:, port:)
          @name = name
          @port = port
        end

        def valid?
          port == "random" || (port.is_a?(Integer) && PORTS.cover?(port))
        end

        def message = "#{name} needs a port from 1 to 65535, or \"random\"."

        private

        PORTS = 1..65_535
        private_constant :PORTS

        attr_reader :name, :port
      end
    end
  end
end
