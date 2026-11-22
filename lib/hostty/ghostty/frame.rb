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
        @cell_reader = CellReader.new(cells:)
        @row_id_memory = FFI::MemoryPointer.new(:uint8, 16)
      end

      def lines
        Library.ghostty_render_state_update(state, terminal)
        @lines = read_lines unless @lines && dirty == Library::RENDER_STATE_DIRTY_FALSE
        Library.ghostty_render_state_clean(state)
        @lines
      end

      private

      attr_reader :terminal, :state, :row_iterator, :cells, :row_iterator_reference, :cells_reference, :cell_reader, :row_id_memory

      def dirty
        value = FFI::MemoryPointer.new(:int)
        Library.ghostty_render_state_get(state, Library::RENDER_STATE_DATA_DIRTY, value)
        value.read_int
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

      def row_dirty?
        value = FFI::MemoryPointer.new(:uint8)
        Library.ghostty_render_state_row_get(row_iterator, Library::ROW_DATA_DIRTY, value)
        !value.read_uint8.zero?
      end

      def read_row
        Library.ghostty_render_state_row_get(row_iterator, Library::ROW_DATA_CELLS, cells_reference)
        row = []
        row << cell_reader.read while Library.ghostty_render_state_row_cells_next(cells)
        row
      end
    end
  end
end
