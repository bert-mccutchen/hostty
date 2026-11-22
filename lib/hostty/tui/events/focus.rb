# frozen_string_literal: true

module Hostty
  module Tui
    module Events
      class Focus
        def initialize(focused:)
          @focused = focused
        end

        def apply(controls) = controls.focus(focused)

        private

        attr_reader :focused
      end
    end
  end
end
