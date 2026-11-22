# frozen_string_literal: true

module Hostty
  module Tui
    class Layout
      attr_reader :rows, :cols

      def initialize(rows:, cols:)
        @rows = rows
        @cols = cols
      end

      def pane_row?(row) = (1..pane_rows).cover?(row)

      def pane_rows = rows - 2

      def pane_point(row:, col:)
        {row: (row - 1).clamp(0, pane_rows - 1), col: col.clamp(0, cols - 1)}
      end

      def resize(rows:, cols:)
        @rows = rows
        @cols = cols
      end
    end
  end
end
