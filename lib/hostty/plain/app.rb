# frozen_string_literal: true

module Hostty
  module Plain
    class App
      def initialize(output:)
        @output = output
      end

      def launch_for(_process)
        Pipe.new(output:)
      end

      def wait(manager)
        manager
          .next_event
          .tap { |event| event.announce(output) }
          .exit_code
      end

      private

      attr_reader :output
    end
  end
end
