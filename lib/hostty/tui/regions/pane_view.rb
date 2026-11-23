# frozen_string_literal: true

module Hostty
  module Tui
    module Regions
      class PaneView
        def initialize(tabs:, layout:)
          @tabs = tabs
          @layout = layout
        end

        def rows
          pane = tabs.selected

          pane.lines.each_with_index.map do |cells, row|
            line_text(cells, pane.selected_columns(row, cells.size))
          end
        end

        def press(row:, col:)
          return false unless layout.pane_row?(row)

          point = layout.pane_point(row:, col:)
          tabs.selected.select_from(**point)
          yield point
          true
        end

        def cursor
          pane = tabs.selected
          position = pane.screen.cursor
          return unless pane.running? && pane.offset.zero? && position

          [position[0] + 1, position[1]]
        end

        private

        attr_reader :tabs, :layout

        def line_text(cells, selected_columns)
          style = nil
          text = +""

          cells.each_with_index do |cell, col|
            next if cell.continuation?

            cell_style = selected_columns&.cover?(col) ? highlight(cell.style) : cell.style
            text << cell_style.sgr unless cell_style.equal?(style)
            style = cell_style
            text << cell.char
          end

          text << Palette::RESET
        end

        def highlight(style)
          Terminal::Style.shared(style.to_h.merge(inverse: !style.inverse))
        end
      end
    end
  end
end
