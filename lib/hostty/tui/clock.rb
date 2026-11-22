# frozen_string_literal: true

module Hostty
  module Tui
    class Clock
      def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
