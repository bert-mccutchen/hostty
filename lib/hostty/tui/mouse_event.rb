# frozen_string_literal: true

module Hostty
  module Tui
    class MouseEvent
      attr_reader :action, :button, :row, :col

      def initialize(action:, button:, row:, col:, modifiers: [])
        @action = action
        @button = button
        @row = row
        @col = col
        @modifiers = modifiers
        freeze
      end

      def shift? = modifiers.include?(:shift)

      def alt? = modifiers.include?(:alt)

      def ctrl? = modifiers.include?(:ctrl)

      def wheel?
        %i[wheel_up wheel_down].include?(button)
      end

      def at(row:)
        self.class.new(action:, button:, row:, col:, modifiers:)
      end

      private

      attr_reader :modifiers
    end
  end
end
