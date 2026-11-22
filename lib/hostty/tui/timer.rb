# frozen_string_literal: true

module Hostty
  module Tui
    class Timer
      def initialize(seconds:, clock:)
        @seconds = seconds
        @clock = clock
      end

      def wait
        return 0 unless fired_at

        (fired_at + seconds - clock.now).clamp(0, seconds)
      end

      def fire
        return unless due?

        yield
        @fired_at = clock.now
      end

      private

      attr_reader :seconds, :clock, :fired_at

      def due?
        fired_at.nil? || clock.now - fired_at >= seconds
      end
    end
  end
end
