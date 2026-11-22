# frozen_string_literal: true

module Hostty
  module Tui
    module Regions
      class TabBar
        def initialize(tabs:, layout:, desktop:)
          @tabs = tabs
          @layout = layout
          @desktop = desktop
        end

        def cursor = nil

        def rows
          spans = tab_spans
          [tab_row(spans, url_start(spans))]
        end

        def press(row:, col:)
          return false unless row.zero?

          spans = tab_spans
          select_tab(spans, col) || open_url(spans, col)
        end

        def blink
          @blink_hidden = !@blink_hidden
        end

        private

        SELECTED_TAB = "\e[0;1;97;48;5;24m"
        RUNNING_DOT = "\e[32m"
        EXITED_DOT = "\e[31m"
        BELL_DOT = "\e[33m"
        private_constant :SELECTED_TAB, :RUNNING_DOT, :EXITED_DOT, :BELL_DOT

        attr_reader :tabs, :layout, :desktop

        def selected = tabs.selected

        def tabs_width(spans) = spans.sum { |span| span[:width] }

        def tab_spans
          start = 0

          tabs.each_with_index.filter_map do |pane, index|
            width = pane.name.length + 4
            next if start + width > layout.cols

            {index:, pane:, start:, width:}.tap { start += width }
          end
        end

        def url_start(spans)
          url = selected.url
          return unless url

          start = layout.cols - url.length - 1
          start if start > tabs_width(spans)
        end

        def tab_row(spans, start)
          text = spans.map { |span| tab_label(span[:pane]) }.join
          return "#{text}#{Palette::BAR}#{" " * (layout.cols - tabs_width(spans))}#{Palette::RESET}" unless start

          "#{text}#{Palette::BAR}#{" " * (start - tabs_width(spans))}#{selected.url} #{Palette::RESET}"
        end

        def tab_label(pane)
          style = pane.equal?(selected) ? SELECTED_TAB : Palette::BAR
          "#{style} #{dot(pane)}#{style} #{pane.name} "
        end

        def dot(pane)
          return "#{BELL_DOT}#{@blink_hidden ? " " : "●"}" if pane.bell?

          "#{pane.running? ? RUNNING_DOT : EXITED_DOT}●"
        end

        def select_tab(spans, col)
          span = spans.find { |candidate| (candidate[:start]...candidate[:start] + candidate[:width]).cover?(col) }
          return false unless span

          tabs.select_at(span[:index])
          true
        end

        def open_url(spans, col)
          start = url_start(spans)
          return false unless start && (start...(start + selected.url.length)).cover?(col)

          desktop.open(selected.url)
          true
        end
      end
    end
  end
end
