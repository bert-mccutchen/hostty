# frozen_string_literal: true

module Hostty
  module Ghostty
    class StyleDecoder
      def initialize
        @styles = Terminal::Flyweight.new
      end

      def decode(bytes)
        styles.fetch(bytes) do
          style(*bytes.unpack("C12S<"))
        end
      end

      private

      attr_reader :styles

      def style(*colors, flags)
        Terminal::Style.shared(
          fg: color(*colors[0, 4]),
          bg: color(*colors[4, 4]),
          bold: flags.anybits?(1 << 0),
          dim: flags.anybits?(1 << 2),
          italic: flags.anybits?(1 << 1),
          underline: flags.anybits?(0b111 << 8),
          blink: flags.anybits?(1 << 3),
          inverse: flags.anybits?(1 << 4),
          invisible: flags.anybits?(1 << 5),
          strikethrough: flags.anybits?(1 << 6),
          overline: flags.anybits?(1 << 7)
        )
      end

      def color(tag, *value)
        case tag
        when 1
          value.first
        when 2
          value
        end
      end
    end
  end
end
