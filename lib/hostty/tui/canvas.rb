# frozen_string_literal: true

module Hostty
  module Tui
    class Canvas
      def initialize(io:, tabs:, display:, clock:)
        @tabs = tabs
        @display = display
        @renderer = Renderer.new(io:)
        @outer_modes = OuterModes.new(io:)
        @frame = Timer.new(seconds: FRAME_SECONDS, clock:)
        @dirty = true
      end

      def invalidate
        @dirty = true
      end

      def reset
        renderer.reset
        invalidate
      end

      def wait
        frame.wait if dirty?
      end

      def tick
        frame.fire { draw } if dirty?
      end

      private

      FRAME_SECONDS = 0.016
      private_constant :FRAME_SECONDS

      attr_reader :tabs, :display, :renderer, :outer_modes, :frame

      def dirty? = @dirty

      def selected = tabs.selected

      def draw
        outer_modes.sync(selected.screen)
        selected.clear_bell
        renderer.render(display)
        @dirty = false
      end
    end
  end
end
