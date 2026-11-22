# frozen_string_literal: true

module Hostty
  module Tui
    module Events
      class MouseReport
        def initialize(mouse:)
          @mouse = mouse
        end

        def apply(controls) = controls.mouse(mouse)

        private

        attr_reader :mouse
      end
    end
  end
end
