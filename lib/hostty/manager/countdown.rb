# frozen_string_literal: true

module Hostty
  class Manager
    class Countdown
      def initialize(seconds:)
        @deadline = now + seconds
        @reminder_at = now + FIRST_REMINDER
      end

      def expired?
        now >= deadline
      end

      def next_wait
        ([deadline, reminder_at].min - now).clamp(0, nil)
      end

      def remind
        return if now < reminder_at

        @reminder_at = now + REMINDER_INTERVAL
        yield (deadline - now).ceil
      end

      private

      FIRST_REMINDER = 1
      REMINDER_INTERVAL = 3
      private_constant :FIRST_REMINDER, :REMINDER_INTERVAL

      attr_reader :deadline, :reminder_at

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
