# frozen_string_literal: true

module Hostty
  class Manager
    class SignalReceived
      def initialize(signal:)
        @signal = signal
      end

      def interrupt? = true

      def exit_code = 0

      def announce(output)
        output.notice("Received SIG#{signal}.")
      end

      private

      attr_reader :signal
    end
  end
end
