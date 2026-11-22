# frozen_string_literal: true

module Hostty
  class Manager
    class ProcessExited
      attr_reader :name

      def initialize(name:, status:)
        @name = name
        @status = status
      end

      def interrupt? = false

      def exit_code
        status.exitstatus || (128 + status.termsig)
      end

      def announce(output)
        output.notice("#{name} exited with code #{exit_code}.")
      end

      private

      attr_reader :status
    end
  end
end
