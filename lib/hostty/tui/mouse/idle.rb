# frozen_string_literal: true

module Hostty
  module Tui
    module Mouse
      class Idle
        def initialize(clock:)
          @clock = clock
        end

        def forward(event, target) = target.forward(event)

        def wait = nil

        def motion(_event, _target) = self

        def release(_event, _target) = self

        def tick(_target) = self

        def press(event, target)
          target.press(event) do |pointer|
            return Selecting.new(pointer:, clock:)
          end

          self
        end

        def wheel(event, target)
          target.wheel(event)
          self
        end

        private

        attr_reader :clock
      end
    end
  end
end
