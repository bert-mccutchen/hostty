# frozen_string_literal: true

module Hostty
  module Ghostty
    class RawCell
      def initialize
        @wide_memory = FFI::MemoryPointer.new(:int)
        @content_memory = FFI::MemoryPointer.new(:int)
        @color_memory = FFI::MemoryPointer.new(:uint8, 4)
        @keys = FFI::MemoryPointer.new(:int, KEYS.size).write_array_of_int(KEYS)
        @values = FFI::MemoryPointer.new(:pointer, KEYS.size).write_array_of_pointer([wide_memory, content_memory])
      end

      def wide = wide_memory.read_int

      def load(raw)
        @raw = raw
        Library.ghostty_cell_get_multi(raw, KEYS.size, keys, values, nil)
      end

      def background
        case content_memory.read_int
        when Library::CELL_CONTENT_BG_COLOR_PALETTE
          color(Library::CELL_DATA_COLOR_PALETTE, 1).first
        when Library::CELL_CONTENT_BG_COLOR_RGB
          color(Library::CELL_DATA_COLOR_RGB, 3)
        end
      end

      private

      KEYS = [Library::CELL_DATA_WIDE, Library::CELL_DATA_CONTENT_TAG].freeze
      private_constant :KEYS

      attr_reader :wide_memory, :content_memory, :color_memory, :keys, :values, :raw

      def color(data, count)
        Library.ghostty_cell_get(raw, data, color_memory)
        color_memory.get_bytes(0, count).bytes
      end
    end
  end
end
