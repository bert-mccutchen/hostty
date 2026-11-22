# frozen_string_literal: true

module Hostty
  module Terminal
    class Cell
      attr_reader :char, :style, :width

      def initialize(char:, style:, width: 1)
        @char = char
        @style = style
        @width = width
        freeze
      end

      def continuation? = width.zero?

      def wide?
        width == 2
      end

      def self.blank(style = Style.plain)
        blanks[style.bg] ||= new(char: " ", style: style.background)
      end

      def self.blanks
        @blanks ||= {}
      end
      private_class_method :blanks

      def self.continuation(style)
        new(char: "", style:, width: 0)
      end
    end
  end
end
