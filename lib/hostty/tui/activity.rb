# frozen_string_literal: true

module Hostty
  module Tui
    class Activity
      def initialize(tabs:, canvas:, controls:)
        @tabs = tabs
        @canvas = canvas
        @controls = controls
      end

      def output(pane)
        canvas.invalidate if tabs.selected?(pane)
      end

      def bell
        controls.ring
        canvas.invalidate
      end

      private

      attr_reader :tabs, :canvas, :controls
    end
  end
end
