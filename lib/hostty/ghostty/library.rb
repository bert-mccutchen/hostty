# frozen_string_literal: true

require "ffi"

module Hostty
  module Ghostty
    module Library
      extend FFI::Library

      FILE_NAME = FFI.map_library_name("ghostty-vt")
      PACKAGED = File.join(__dir__, FILE_NAME)
      DEVELOPMENT = File.expand_path("../../../vendor/libghostty/lib/#{FILE_NAME}", __dir__)

      ffi_lib [PACKAGED, DEVELOPMENT, "ghostty-vt"]

      SUCCESS = 0
      OUT_OF_SPACE = -3

      TERMINAL_OPT_WRITE_PTY = 2
      TERMINAL_OPT_BELL = 3
      TERMINAL_OPT_SCROLLBACK_MAX_BYTES = 28
      TERMINAL_OPT_SCROLLBACK_MAX_LINES = 29

      TERMINAL_DATA_CURSOR_X = 3
      TERMINAL_DATA_CURSOR_Y = 4
      TERMINAL_DATA_ACTIVE_SCREEN = 6
      TERMINAL_DATA_CURSOR_VISIBLE = 7
      TERMINAL_DATA_MOUSE_TRACKING = 11
      TERMINAL_DATA_SCROLLBACK_ROWS = 15
      TERMINAL_DATA_MODE = 37

      MODE_CURSOR_KEYS = 1
      MODE_FOCUS_EVENTS = 1004
      MODE_BRACKETED_PASTE = 2004

      TERMINAL_SCREEN_ALTERNATE = 1

      MOUSE_ACTIONS = {press: 0, release: 1, motion: 2}.freeze
      MOUSE_BUTTONS = {left: 1, right: 2, middle: 3, wheel_up: 4, wheel_down: 5}.freeze
      MOUSE_ENCODER_OPT_SIZE = 3
      MOUSE_ENCODER_OPT_ANY_BUTTON_PRESSED = 4
      MODS = {shift: 1 << 0, ctrl: 1 << 1, alt: 1 << 2}.freeze

      SCROLL_VIEWPORT_BOTTOM = 1
      SCROLL_VIEWPORT_DELTA = 2

      RENDER_STATE_DATA_DIRTY = 3
      RENDER_STATE_DATA_ROW_ITERATOR = 4
      RENDER_STATE_DIRTY_FALSE = 0
      RENDER_STATE_DIRTY_FULL = 2

      ROW_DATA_DIRTY = 1
      ROW_DATA_CELLS = 3
      ROW_DATA_ID = 7

      ROW_CELLS_DATA_RAW = 1
      ROW_CELLS_DATA_STYLE = 2
      ROW_CELLS_DATA_GRAPHEMES_UTF8 = 9

      CELL_DATA_CONTENT_TAG = 2
      CELL_DATA_WIDE = 3
      CELL_DATA_COLOR_PALETTE = 10
      CELL_DATA_COLOR_RGB = 11

      CELL_CONTENT_BG_COLOR_PALETTE = 2
      CELL_CONTENT_BG_COLOR_RGB = 3

      CELL_WIDE_WIDE = 1
      CELL_WIDE_SPACER_TAIL = 2

      class ScrollViewport < FFI::Struct
        layout :tag, :int, 0, :delta, :int64, 8, :padding, :uint64, 16
      end

      class Buffer < FFI::Struct
        layout :ptr, :pointer, :cap, :size_t, :len, :size_t
      end

      class MousePosition < FFI::Struct
        layout :x, :float, :y, :float
      end

      class MouseEncoderSize < FFI::Struct
        layout :size, :size_t,
          :screen_width, :uint32,
          :screen_height, :uint32,
          :cell_width, :uint32,
          :cell_height, :uint32,
          :padding_top, :uint32,
          :padding_bottom, :uint32,
          :padding_right, :uint32,
          :padding_left, :uint32
      end

      callback :write_pty, %i[pointer pointer pointer size_t], :void

      attach_function :ghostty_terminal_new, %i[pointer pointer uint16 uint16], :int
      attach_function :ghostty_terminal_free, [:pointer], :void
      attach_function :ghostty_terminal_resize, %i[pointer uint16 uint16 uint32 uint32], :int
      attach_function :ghostty_terminal_set, %i[pointer int pointer], :int
      attach_function :ghostty_terminal_vt_write, %i[pointer buffer_in size_t], :void
      attach_function :ghostty_terminal_get, %i[pointer int pointer], :int
      attach_function :ghostty_terminal_scroll_viewport, [:pointer, ScrollViewport.by_value], :int

      attach_function :ghostty_render_state_new, %i[pointer pointer], :int
      attach_function :ghostty_render_state_free, [:pointer], :void
      attach_function :ghostty_render_state_update, %i[pointer pointer], :int
      attach_function :ghostty_render_state_get, %i[pointer int pointer], :int
      attach_function :ghostty_render_state_clean, [:pointer], :int

      attach_function :ghostty_render_state_row_iterator_new, %i[pointer pointer], :int
      attach_function :ghostty_render_state_row_iterator_free, [:pointer], :void
      attach_function :ghostty_render_state_row_iterator_next, [:pointer], :bool
      attach_function :ghostty_render_state_row_get, %i[pointer int pointer], :int

      attach_function :ghostty_render_state_row_cells_new, %i[pointer pointer], :int
      attach_function :ghostty_render_state_row_cells_free, [:pointer], :void
      attach_function :ghostty_render_state_row_cells_next, [:pointer], :bool
      attach_function :ghostty_render_state_row_cells_get_multi, %i[pointer size_t pointer pointer pointer], :int

      attach_function :ghostty_cell_get, %i[uint64 int pointer], :int
      attach_function :ghostty_cell_get_multi, %i[uint64 size_t pointer pointer pointer], :int

      attach_function :ghostty_mouse_encoder_new, %i[pointer pointer], :int
      attach_function :ghostty_mouse_encoder_free, [:pointer], :void
      attach_function :ghostty_mouse_encoder_set, %i[pointer int pointer], :int
      attach_function :ghostty_mouse_encoder_set_from_terminal, %i[pointer pointer], :int
      attach_function :ghostty_mouse_encoder_encode, %i[pointer pointer pointer size_t pointer], :int

      attach_function :ghostty_mouse_event_new, %i[pointer pointer], :int
      attach_function :ghostty_mouse_event_free, [:pointer], :void
      attach_function :ghostty_mouse_event_set_action, %i[pointer int], :int
      attach_function :ghostty_mouse_event_set_button, %i[pointer int], :int
      attach_function :ghostty_mouse_event_set_mods, %i[pointer uint16], :int
      attach_function :ghostty_mouse_event_set_position, [:pointer, MousePosition.by_value], :int

      def self.create(constructor, destructor, *arguments)
        reference = FFI::MemoryPointer.new(:pointer)
        result = public_send(constructor, nil, reference, *arguments)
        raise Error, "#{constructor} failed with #{result}" unless result == SUCCESS

        FFI::AutoPointer.new(reference.read_pointer, method(destructor))
      end

      def self.reference(handle)
        FFI::MemoryPointer.new(:pointer).write_pointer(handle)
      end
    end
  end
end
