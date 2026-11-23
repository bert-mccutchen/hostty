# frozen_string_literal: true

module Hostty
  module Tui
    class Tabs
      include Enumerable

      def initialize
        @panes = []
        @index = 0
      end

      def selected?(pane) = selected.equal?(pane)

      def selected = panes[index]

      def each(&) = panes.each(&)

      def add(pane)
        panes << pane
      end

      def select_next
        @index = (index + 1) % panes.size
      end

      def select_at(position)
        @index = position
      end

      def named(name)
        find do |pane|
          pane.name == name
        end
      end

      private

      attr_reader :panes, :index
    end
  end
end
