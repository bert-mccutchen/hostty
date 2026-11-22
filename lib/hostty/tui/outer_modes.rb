# frozen_string_literal: true

module Hostty
  module Tui
    class OuterModes
      def initialize(io:)
        @io = io
        @enabled = {}
      end

      def sync(screen)
        MODES.each do |query, mode|
          enabled = screen.public_send(query)
          next if @enabled[mode] == enabled

          io.write("\e[?#{mode}#{enabled ? "h" : "l"}")
          @enabled[mode] = enabled
        end
      end

      private

      MODES = {application_cursor_keys?: 1, bracketed_paste?: 2004}.freeze
      private_constant :MODES

      attr_reader :io
    end
  end
end
