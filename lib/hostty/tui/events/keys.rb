# frozen_string_literal: true

module Hostty
  module Tui
    module Events
      class Keys
        def initialize(bytes:)
          @bytes = bytes
        end

        def apply(controls) = controls.type(bytes)

        private

        attr_reader :bytes
      end
    end
  end
end
