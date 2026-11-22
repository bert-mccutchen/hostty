# frozen_string_literal: true

module Hostty
  module Tui
    class Renderer
      def initialize(io:)
        @io = io
        @previous = []
      end

      def reset
        @previous = []
      end

      def render(display)
        rows = display.rows
        frame = +""
        rows.each_with_index { |row, index| frame << "\e[#{index + 1};1H#{row}" unless @previous[index] == row }
        @previous = rows
        io.write(frame << cursor(display.cursor))
      end

      private

      attr_reader :io

      def cursor(position)
        return "\e[?25l" unless position

        "\e[#{position[0] + 1};#{position[1] + 1}H\e[?25h"
      end
    end
  end
end
