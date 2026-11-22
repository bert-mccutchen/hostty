# frozen_string_literal: true

module Hostty
  module Tui
    class Blink
      def initialize(tabs:, tab_bar:, canvas:, clock:)
        @tabs = tabs
        @tab_bar = tab_bar
        @canvas = canvas
        @timer = Timer.new(seconds: SECONDS, clock:)
      end

      def wait
        timer.wait if ringing?
      end

      def tick
        timer.fire { flash } if ringing?
      end

      private

      SECONDS = 0.5
      private_constant :SECONDS

      attr_reader :tabs, :tab_bar, :canvas, :timer

      def ringing? = tabs.any?(&:bell?)

      def flash
        tab_bar.blink
        canvas.invalidate
      end
    end
  end
end
