# frozen_string_literal: true

module Hostty
  module Tui
    module Mouse
      class Pointer
        def initialize(target:, canvas:, clock:)
          @target = target
          @canvas = canvas
          @state = Idle.new(clock:)
        end

        def wait = state.wait

        def handle(event)
          return if state.forward(event, target)

          @state = transition(event)
        end

        def tick
          @state = state.tick(target) { canvas.invalidate }
        end

        private

        attr_reader :state, :target, :canvas

        def transition(event)
          return state.wheel(event, target) if event.wheel?
          return state unless event.button == :left

          case event.action
          when :press
            state.press(event, target)
          when :motion
            state.motion(event, target)
          when :release
            state.release(event, target)
          end
        end
      end
    end
  end
end
