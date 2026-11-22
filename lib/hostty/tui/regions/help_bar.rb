# frozen_string_literal: true

module Hostty
  module Tui
    module Regions
      class HelpBar
        def initialize(tabs:, layout:, manager:)
          @tabs = tabs
          @layout = layout
          @manager = manager
        end

        def cursor = nil

        def rows
          text = help_text[0, layout.cols].ljust(layout.cols)
          ["#{Palette::BAR}#{text.sub(RESTART_BUTTON, "\e[1;97m#{RESTART_BUTTON}#{Palette::BAR}")}#{Palette::RESET}"]
        end

        def press(row:, col:)
          return false unless restart_at?(row:, col:)

          selected.restart(manager)
          true
        end

        private

        RESTART_BUTTON = "[restart]"
        private_constant :RESTART_BUTTON

        attr_reader :tabs, :layout, :manager

        def selected = tabs.selected

        def restart_at?(row:, col:)
          start = help_text.index(RESTART_BUTTON)
          row == layout.rows - 1 && (start...(start + RESTART_BUTTON.length)).cover?(col)
        end

        def help_text
          scroll = selected.offset.positive? ? "Scrolled up #{selected.offset}" : "Scroll: history"
          " Switch: click or Shift+Tab | #{scroll} | #{RESTART_BUTTON} | Quit: Ctrl-C twice "
        end
      end
    end
  end
end
