# frozen_string_literal: true

module Hostty
  module Tui
    class Outcome
      attr_reader :exit_code

      def decided? = !exit_code.nil?

      def decide(exit_code)
        @exit_code = exit_code
      end
    end
  end
end
