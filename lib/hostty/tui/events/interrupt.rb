# frozen_string_literal: true

module Hostty
  module Tui
    module Events
      class Interrupt
        def initialize(bytes:)
          @bytes = bytes
        end

        def apply(controls) = controls.interrupt(bytes)

        private

        attr_reader :bytes
      end
    end
  end
end
