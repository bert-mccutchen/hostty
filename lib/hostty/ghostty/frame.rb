# frozen_string_literal: true

module Hostty
  module Ghostty
    class Frame
      def initialize(terminal:)
        @terminal = terminal
        @state = Library.create(:ghostty_render_state_new, :ghostty_render_state_free)
        @row_iterator = Library.create(:ghostty_render_state_row_iterator_new, :ghostty_render_state_row_iterator_free)
        @cells = Library.create(:ghostty_render_state_row_cells_new, :ghostty_render_state_row_cells_free)
        @row_iterator_reference = Library.reference(row_iterator)
        @cells_reference = Library.reference(cells)
        @styles = {}
      end

      def lines
        Library.ghostty_render_state_update(state, terminal)
        @lines = read_lines unless @lines && dirty == Library::RENDER_STATE_DIRTY_FALSE
        Library.ghostty_render_state_clean(state)
        @lines
      end

      private

      KEYS = [Library::ROW_CELLS_DATA_RAW, Library::ROW_CELLS_DATA_STYLE, Library::ROW_CELLS_DATA_GRAPHEMES_UTF8].freeze
      CELL_KEYS = [Library::CELL_DATA_WIDE, Library::CELL_DATA_CONTENT_TAG].freeze
      TEXT_CAPACITY = 256
      STYLE_LIMIT = 1024
      private_constant :KEYS, :CELL_KEYS, :TEXT_CAPACITY, :STYLE_LIMIT

      attr_reader :terminal, :state, :row_iterator, :cells, :row_iterator_reference, :cells_reference, :styles

      def dirty
        read_state(:int, Library::RENDER_STATE_DATA_DIRTY)
      end

      def read_state(type, data)
        value = FFI::MemoryPointer.new(type)
        Library.ghostty_render_state_get(state, data, value)
        value.read(type)
      end

      def read_lines
        previous = (dirty == Library::RENDER_STATE_DIRTY_FULL) ? {} : @rows_by_id || {}
        @rows_by_id = {}
        Library.ghostty_render_state_get(state, Library::RENDER_STATE_DATA_ROW_ITERATOR, row_iterator_reference)
        @rows_by_id[row_id] = ((!row_dirty? && previous[row_id]) || read_row) while Library.ghostty_render_state_row_iterator_next(row_iterator)
        @rows_by_id.values
      end

      def row_id
        Library.ghostty_render_state_row_get(row_iterator, Library::ROW_DATA_ID, row_id_memory)
        row_id_memory.get_bytes(0, 16)
      end

      def row_id_memory
        @row_id_memory ||= FFI::MemoryPointer.new(:uint8, 16)
      end

      def row_dirty?
        value = FFI::MemoryPointer.new(:uint8)
        Library.ghostty_render_state_row_get(row_iterator, Library::ROW_DATA_DIRTY, value)
        !value.read_uint8.zero?
      end

      def read_row
        Library.ghostty_render_state_row_get(row_iterator, Library::ROW_DATA_CELLS, cells_reference)
        row = []
        row << read_cell while Library.ghostty_render_state_row_cells_next(cells)
        row
      end

      def read_cell
        result = Library.ghostty_render_state_row_cells_get_multi(cells, KEYS.size, keys, values, nil)
        text = (result == Library::SUCCESS) ? text_memory.get_bytes(0, text_buffer[:len]).force_encoding(Encoding::UTF_8) : "�"
        build_cell(text, raw_memory.read_uint64)
      end

      def build_cell(text, raw)
        style_bytes = style_memory.get_bytes(0, 16)
        return narrow_cell(text, style_bytes) if text.bytesize == 1

        Library.ghostty_cell_get_multi(raw, CELL_KEYS.size, cell_keys, cell_values, nil)

        case wide_memory.read_int
        when Library::CELL_WIDE_SPACER_TAIL
          Terminal::Cell.continuation(style_for(style_bytes))
        when Library::CELL_WIDE_WIDE
          Terminal::Cell.new(char: text, style: style_for(style_bytes), width: 2)
        else
          text.empty? ? blank_cell(raw, style_bytes) : Terminal::Cell.new(char: text, style: style_for(style_bytes))
        end
      end

      def narrow_cell(text, style_bytes)
        cells = narrow_cells[style_bytes] ||= {}
        cells[text] ||= Terminal::Cell.new(char: text, style: style_for(style_bytes))
      end

      def narrow_cells
        @narrow_cells = {} if @narrow_cells.nil? || @narrow_cells.size > STYLE_LIMIT
        @narrow_cells
      end

      def blank_cell(raw, style_bytes)
        case content_memory.read_int
        when Library::CELL_CONTENT_BG_COLOR_PALETTE
          background_cell(style_bytes, cell_bytes(raw, Library::CELL_DATA_COLOR_PALETTE, 1).first)
        when Library::CELL_CONTENT_BG_COLOR_RGB
          background_cell(style_bytes, cell_bytes(raw, Library::CELL_DATA_COLOR_RGB, 3))
        else
          narrow_cell(" ", style_bytes)
        end
      end

      def background_cell(style_bytes, bg)
        Terminal::Cell.blank(Terminal::Style.shared(style_for(style_bytes).to_h.merge(bg:)))
      end

      def cell_bytes(raw, data, count)
        Library.ghostty_cell_get(raw, data, color_memory)
        color_memory.get_bytes(0, count).bytes
      end

      def style_for(bytes)
        styles.clear if styles.size > STYLE_LIMIT
        styles[bytes] ||= decode_style(*bytes.unpack("C12S<"))
      end

      def decode_style(*colors, flags)
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

      def raw_memory
        @raw_memory ||= FFI::MemoryPointer.new(:uint64)
      end

      def style_memory
        @style_memory ||= FFI::MemoryPointer.new(:uint8, 16)
      end

      def text_memory
        @text_memory ||= FFI::MemoryPointer.new(:uint8, TEXT_CAPACITY)
      end

      def text_buffer
        @text_buffer ||= Library::Buffer.new.tap do |buffer|
          buffer[:ptr] = text_memory
          buffer[:cap] = TEXT_CAPACITY
        end
      end

      def wide_memory
        @wide_memory ||= FFI::MemoryPointer.new(:int)
      end

      def content_memory
        @content_memory ||= FFI::MemoryPointer.new(:int)
      end

      def color_memory
        @color_memory ||= FFI::MemoryPointer.new(:uint8, 4)
      end

      def cell_keys
        @cell_keys ||= FFI::MemoryPointer.new(:int, CELL_KEYS.size).write_array_of_int(CELL_KEYS)
      end

      def cell_values
        @cell_values ||= FFI::MemoryPointer.new(:pointer, CELL_KEYS.size).write_array_of_pointer([wide_memory, content_memory])
      end

      def keys
        @keys ||= FFI::MemoryPointer.new(:int, KEYS.size).write_array_of_int(KEYS)
      end

      def values
        @values ||= FFI::MemoryPointer.new(:pointer, KEYS.size).write_array_of_pointer([raw_memory, style_memory, text_buffer.pointer])
      end
    end
  end
end
