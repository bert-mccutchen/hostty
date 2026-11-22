# frozen_string_literal: true

module Hostty
  module Tui
    class Selection
      def initialize(anchor:, head: anchor)
        @anchor = anchor
        @head = head
        freeze
      end

      def empty?
        anchor == head
      end

      def rows = first[0]..last[0]

      def to(head)
        self.class.new(anchor:, head:)
      end

      def columns(row, width)
        return unless rows.cover?(row)

        start_col = (row == first[0]) ? first[1] : 0
        end_col = (row == last[0]) ? last[1] : width - 1
        start_col..end_col
      end

      def text(lines)
        rows.map { |row| row_text(lines[row] || [], row) }.join("\n")
      end

      private

      attr_reader :anchor, :head

      def first = [anchor, head].min

      def last = [anchor, head].max

      def row_text(cells, row)
        cells[columns(row, cells.size)].to_a.reject(&:continuation?).map(&:char).join.rstrip
      end
    end
  end
end
