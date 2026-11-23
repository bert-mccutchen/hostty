# frozen_string_literal: true

module Hostty
  module Ghostty
    class CellReader
      def initialize(cells:)
        @cells = cells
        @raw_cell = RawCell.new
        @style_decoder = StyleDecoder.new
        @narrow_cells = Terminal::Flyweight.new
        @raw_memory = FFI::MemoryPointer.new(:uint64)
        @style_memory = FFI::MemoryPointer.new(:uint8, 16)
        @text_memory = FFI::MemoryPointer.new(:uint8, TEXT_CAPACITY)
        @text_buffer =
          Library::Buffer.new.tap do |buffer|
            buffer[:ptr] = text_memory
            buffer[:cap] = TEXT_CAPACITY
          end
        @keys = FFI::MemoryPointer.new(:int, KEYS.size).write_array_of_int(KEYS)
        @values = FFI::MemoryPointer.new(:pointer, KEYS.size).write_array_of_pointer([raw_memory, style_memory, text_buffer.pointer])
      end

      def read
        result = Library.ghostty_render_state_row_cells_get_multi(cells, KEYS.size, keys, values, nil)
        build((result == Library::SUCCESS) ? text : "�", style_memory.get_bytes(0, 16))
      end

      private

      KEYS = [Library::ROW_CELLS_DATA_RAW, Library::ROW_CELLS_DATA_STYLE, Library::ROW_CELLS_DATA_GRAPHEMES_UTF8].freeze
      TEXT_CAPACITY = 256
      private_constant :KEYS, :TEXT_CAPACITY

      attr_reader :cells, :raw_cell, :style_decoder, :narrow_cells, :raw_memory, :style_memory, :text_memory, :text_buffer, :keys, :values

      def text
        text_memory.get_bytes(0, text_buffer[:len]).force_encoding(Encoding::UTF_8)
      end

      def build(text, style_bytes)
        return narrow(text, style_bytes) if text.bytesize == 1

        raw_cell.load(raw_memory.read_uint64)

        case raw_cell.wide
        when Library::CELL_WIDE_SPACER_TAIL
          Terminal::Cell.continuation(style_decoder.decode(style_bytes))
        when Library::CELL_WIDE_WIDE
          Terminal::Cell.new(char: text, style: style_decoder.decode(style_bytes), width: 2)
        else
          text.empty? ? blank(style_bytes) : Terminal::Cell.new(char: text, style: style_decoder.decode(style_bytes))
        end
      end

      def narrow(text, style_bytes)
        cells_by_text = narrow_cells.fetch(style_bytes) { {} }

        cells_by_text[text] ||= Terminal::Cell.new(char: text, style: style_decoder.decode(style_bytes))
      end

      def blank(style_bytes)
        background = raw_cell.background
        return narrow(" ", style_bytes) unless background

        Terminal::Cell.blank(Terminal::Style.shared(style_decoder.decode(style_bytes).to_h.merge(bg: background)))
      end
    end
  end
end
