# frozen_string_literal: true

module Hostty
  module Terminal
    class Style
      ATTRIBUTES = %i[fg bg bold dim italic underline blink inverse invisible strikethrough overline].freeze

      attr_reader(*ATTRIBUTES)

      def initialize(fg: nil, bg: nil, **flags)
        @fg = fg
        @bg = bg

        FLAG_CODES.each_key do |flag|
          instance_variable_set(:"@#{flag}", flags.fetch(flag, false))
        end

        freeze
      end

      def ==(other)
        other.is_a?(Style) && to_h == other.to_h
      end

      alias_method :eql?, :==

      def hash = to_h.hash

      def to_h
        ATTRIBUTES.to_h do |attribute|
          [attribute, public_send(attribute)]
        end
      end

      def background
        self.class.shared(Style.plain.to_h.merge(bg:))
      end

      def sgr
        codes = [0]

        FLAG_CODES.each do |flag, code|
          codes << code if public_send(flag)
        end

        codes.concat(color_codes(fg, base: 30, extended: 38))
        codes.concat(color_codes(bg, base: 40, extended: 48))
        "\e[#{codes.join(";")}m"
      end

      def self.plain
        @plain ||= new
      end

      def self.shared(attributes)
        styles.fetch(attributes.values) do
          new(**attributes)
        end
      end

      def self.styles
        @styles ||=
          Flyweight.new.tap do |styles|
            styles.fetch(plain.to_h.values) do
              plain
            end
          end
      end
      private_class_method :styles

      private

      FLAG_CODES = {
        bold: 1,
        dim: 2,
        italic: 3,
        underline: 4,
        blink: 5,
        inverse: 7,
        invisible: 8,
        strikethrough: 9,
        overline: 53
      }.freeze
      private_constant :FLAG_CODES

      def color_codes(color, base:, extended:)
        case color
        when nil
          []
        when 0..7
          [base + color]
        when 8..15
          [base + 52 + color]
        when Integer
          [extended, 5, color]
        else
          [extended, 2, *color]
        end
      end
    end
  end
end
