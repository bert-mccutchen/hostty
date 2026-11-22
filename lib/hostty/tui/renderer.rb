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

      def blink
        @blink_hidden = !@blink_hidden
      end

      def render(layout:, panes:, selected:)
        rows = [tab_row(layout, panes, selected), *pane_rows(selected), help_row(layout, selected)]
        frame = +""
        rows.each_with_index { |row, index| frame << "\e[#{index + 1};1H#{row}" unless @previous[index] == row }
        @previous = rows
        io.write(frame << cursor(selected))
      end

      private

      BAR = "\e[0;37;48;5;236m"
      SELECTED_TAB = "\e[0;1;97;48;5;24m"
      RUNNING_DOT = "\e[32m"
      EXITED_DOT = "\e[31m"
      BELL_DOT = "\e[33m"
      RESET = "\e[0m"
      private_constant :BAR, :SELECTED_TAB, :RUNNING_DOT, :EXITED_DOT, :BELL_DOT, :RESET

      attr_reader :io

      def tab_row(layout, panes, selected)
        text = layout.tabs.map { |tab| tab_label(panes[tab[:index]], selected) }.join
        start = layout.url_start(selected.url)
        return "#{text}#{BAR}#{" " * (layout.cols - layout.tabs_width)}#{RESET}" unless start

        "#{text}#{BAR}#{" " * (start - layout.tabs_width)}#{selected.url} #{RESET}"
      end

      def tab_label(pane, selected)
        style = pane.equal?(selected) ? SELECTED_TAB : BAR
        "#{style} #{dot(pane)}#{style} #{pane.name} "
      end

      def dot(pane)
        return "#{BELL_DOT}#{@blink_hidden ? " " : "●"}" if pane.bell?

        "#{pane.running? ? RUNNING_DOT : EXITED_DOT}●"
      end

      def pane_rows(pane)
        pane.lines.each_with_index.map { |cells, row| line_text(cells, pane.selected_columns(row, cells.size)) }
      end

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

        text << RESET
      end

      def highlight(style)
        Terminal::Style.shared(style.to_h.merge(inverse: !style.inverse))
      end

      def help_row(layout, pane)
        text = layout.help_text(offset: pane.offset)[0, layout.cols].ljust(layout.cols)
        "#{BAR}#{text.sub(Layout::RESTART_BUTTON, "\e[1;97m#{Layout::RESTART_BUTTON}#{BAR}")}#{RESET}"
      end

      def cursor(pane)
        position = pane.screen.cursor
        return "\e[?25l" unless pane.running? && pane.offset.zero? && position

        "\e[#{position[0] + 2};#{position[1] + 1}H\e[?25h"
      end
    end
  end
end
