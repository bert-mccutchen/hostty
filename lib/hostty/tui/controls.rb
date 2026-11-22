# frozen_string_literal: true

module Hostty
  module Tui
    class Controls
      def initialize(tabs:, desktop:, pointer:, clock:)
        @tabs = tabs
        @desktop = desktop
        @pointer = pointer
        @clock = clock
        @focused = true
        @quit = false
      end

      def quit? = @quit

      def type(bytes)
        selected.write(bytes)
      end

      def interrupt(bytes)
        return @quit = true if double_press?

        @interrupted_at = clock.now
        selected.write(bytes)
      end

      def select_next
        tabs.select_next
      end

      def focus(focused)
        @focused = focused
        selected.send_focus(focused)
      end

      def mouse(event)
        pointer.handle(event)
      end

      def ring
        desktop.ring unless @focused
      end

      private

      DOUBLE_PRESS_SECONDS = 0.5
      private_constant :DOUBLE_PRESS_SECONDS

      attr_reader :tabs, :desktop, :pointer, :clock

      def selected = tabs.selected

      def double_press?
        !@interrupted_at.nil? && clock.now - @interrupted_at <= DOUBLE_PRESS_SECONDS
      end
    end
  end
end
