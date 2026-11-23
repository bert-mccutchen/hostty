# frozen_string_literal: true

module Hostty
  module Tui
    module Mouse
      class Selecting
        def initialize(pointer:, clock:)
          @pointer = pointer
          @clock = clock
          @autoscroll = Timer.new(seconds: AUTOSCROLL_SECONDS, clock:)
        end

        def forward(_event, _target) = false

        def wait
          AUTOSCROLL_SECONDS if @direction
        end

        def press(event, target)
          target.press(event) do |point|
            @pointer = point
          end

          self
        end

        def motion(event, target)
          @pointer = target.drag(event)
          direction = target.direction(event)
          @started_at = clock.now unless direction == @direction
          @direction = direction
          self
        end

        def release(event, target)
          target.release(event)
          Idle.new(clock:)
        end

        def wheel(event, target)
          target.wheel(event, pointer:)
          self
        end

        def tick(target)
          return self unless @direction

          autoscroll.fire do
            target.autoscroll(lines: @direction * lines, pointer:)
            yield
          end
          self
        end

        private

        AUTOSCROLL_SECONDS = 0.025
        SPEEDUP_SECONDS = 0.5
        MAX_LINES = 10
        private_constant :AUTOSCROLL_SECONDS, :SPEEDUP_SECONDS, :MAX_LINES

        attr_reader :pointer, :clock, :autoscroll

        def lines
          (1 + ((clock.now - @started_at) / SPEEDUP_SECONDS).floor).clamp(1, MAX_LINES)
        end
      end
    end
  end
end
