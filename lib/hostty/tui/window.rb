# frozen_string_literal: true

module Hostty
  module Tui
    class Window
      def initialize(io:, layout:, tabs:, canvas:)
        @io = io
        @layout = layout
        @tabs = tabs
        @canvas = canvas
      end

      def wait = IDLE_SECONDS

      def tick
        rows, cols = io.winsize
        return if [rows, cols] == [layout.rows, layout.cols]

        layout.resize(rows:, cols:)
        tabs.each { |pane| pane.resize(rows: layout.pane_rows, cols:) }
        canvas.reset
      end

      private

      IDLE_SECONDS = 0.25
      private_constant :IDLE_SECONDS

      attr_reader :io, :layout, :tabs, :canvas
    end
  end
end
