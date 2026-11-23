# frozen_string_literal: true

module Hostty
  module Tui
    class Display
      def initialize(tab_bar:, tabs:, layout:, manager:)
        @regions = [
          tab_bar,
          Regions::PaneView.new(tabs:, layout:),
          Regions::HelpBar.new(tabs:, layout:, manager:)
        ]
      end

      def rows = regions.flat_map(&:rows)

      def cursor = regions.lazy.filter_map(&:cursor).first

      def press(row:, col:, &)
        regions.any? do |region|
          region.press(row:, col:, &)
        end
      end

      private

      attr_reader :regions
    end
  end
end
