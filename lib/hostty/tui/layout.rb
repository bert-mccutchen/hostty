# frozen_string_literal: true

module Hostty
  module Tui
    class Layout
      RESTART_BUTTON = "[restart]"

      attr_reader :rows, :cols

      def initialize(names:, rows:, cols:)
        @names = names
        @rows = rows
        @cols = cols
      end

      def pane_rows = rows - 2

      def help_row = rows - 1

      def tabs_width = tabs.sum { |tab| tab[:width] }

      def tabs
        @tabs ||= begin
          start = 0

          names.each_with_index.filter_map do |name, index|
            width = name.length + 4
            next if start + width > cols

            {index:, start:, width:}.tap { start += width }
          end
        end
      end

      def url_start(url)
        return unless url

        start = cols - url.length - 1
        start if start > tabs_width
      end

      def url_at?(row:, col:, url:)
        start = url_start(url)
        row.zero? && !start.nil? && (start...(start + url.length)).cover?(col)
      end

      def tab_at(row:, col:)
        return unless row.zero?

        tabs.find { |tab| (tab[:start]...tab[:start] + tab[:width]).cover?(col) }&.fetch(:index)
      end

      def help_text(offset:)
        scroll = offset.positive? ? "Scrolled up #{offset}" : "Scroll: history"
        " Switch: click or Shift+Tab | #{scroll} | #{RESTART_BUTTON} | Quit: Ctrl-C twice "
      end

      def restart_at?(row:, col:, offset:)
        start = help_text(offset:).index(RESTART_BUTTON)
        row == help_row && (start...(start + RESTART_BUTTON.length)).cover?(col)
      end

      private

      attr_reader :names
    end
  end
end
