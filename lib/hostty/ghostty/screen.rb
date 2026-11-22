# frozen_string_literal: true

require_relative "library"
require_relative "style_decoder"
require_relative "raw_cell"
require_relative "cell_reader"
require_relative "frame"
require_relative "mouse"

module Hostty
  module Ghostty
    class Screen
      def initialize(rows:, cols:, reply: nil, bell: nil)
        @reply = reply
        @bell = bell
        @rows = rows
        @cols = cols
        @terminal = Library.create(:ghostty_terminal_new, :ghostty_terminal_free, cols, rows)
        @frame = Frame.new(terminal:)
        @mouse = Mouse.new(terminal:)
        limit_scrollback
        send_replies
        send_bells
      end

      def application_cursor_keys? = mode?(Library::MODE_CURSOR_KEYS)

      def bracketed_paste? = mode?(Library::MODE_BRACKETED_PASTE)

      def focus_events? = mode?(Library::MODE_FOCUS_EVENTS)

      def mouse_tracking? = !read(:uint8, Library::TERMINAL_DATA_MOUSE_TRACKING).zero?

      def scrollback_size = read(:size_t, Library::TERMINAL_DATA_SCROLLBACK_ROWS)

      def alternate_screen?
        read(:int, Library::TERMINAL_DATA_ACTIVE_SCREEN) == Library::TERMINAL_SCREEN_ALTERNATE
      end

      def encode_mouse(event)
        mouse.encode(event, rows:, cols:)
      end

      def feed(data)
        Library.ghostty_terminal_vt_write(terminal, data, data.bytesize)
      end

      def lines(offset: 0)
        scroll_to(offset) unless offset.zero? && @offset.to_i.zero?
        frame.lines
      end

      def cursor
        return if read(:uint8, Library::TERMINAL_DATA_CURSOR_VISIBLE).zero?

        [read(:uint16, Library::TERMINAL_DATA_CURSOR_Y), read(:uint16, Library::TERMINAL_DATA_CURSOR_X)]
      end

      def resize(rows:, cols:)
        @rows = rows
        @cols = cols
        Library.ghostty_terminal_resize(terminal, cols, rows, CELL_WIDTH, CELL_HEIGHT)
      end

      private

      SCROLLBACK_LINES = 5000
      SCROLLBACK_BYTES = 64 * 1024 * 1024
      CELL_WIDTH = 8
      CELL_HEIGHT = 16
      private_constant :SCROLLBACK_LINES, :SCROLLBACK_BYTES, :CELL_WIDTH, :CELL_HEIGHT

      attr_reader :reply, :bell, :rows, :cols, :terminal, :frame, :mouse

      def limit_scrollback
        set_size(Library::TERMINAL_OPT_SCROLLBACK_MAX_LINES, SCROLLBACK_LINES)
        set_size(Library::TERMINAL_OPT_SCROLLBACK_MAX_BYTES, SCROLLBACK_BYTES)
      end

      def set_size(option, value)
        Library.ghostty_terminal_set(terminal, option, FFI::MemoryPointer.new(:size_t).write(:size_t, value))
      end

      def send_replies
        @write_pty = FFI::Function.new(:void, %i[pointer pointer pointer size_t]) do |_terminal, _userdata, data, length|
          reply&.write(data.read_bytes(length))
        end

        Library.ghostty_terminal_set(terminal, Library::TERMINAL_OPT_WRITE_PTY, @write_pty)
      end

      def send_bells
        @ring = FFI::Function.new(:void, %i[pointer pointer]) { |_terminal, _userdata| bell&.call }
        Library.ghostty_terminal_set(terminal, Library::TERMINAL_OPT_BELL, @ring)
      end

      def read(type, data)
        value = FFI::MemoryPointer.new(type)
        Library.ghostty_terminal_get(terminal, data, value)
        value.read(type)
      end

      def mode?(number)
        config = FFI::MemoryPointer.new(:uint8, 4)
        config.put(:uint16, 0, number)
        Library.ghostty_terminal_get(terminal, Library::TERMINAL_DATA_MODE, config)
        !config.get(:uint8, 2).zero?
      end

      def scroll_to(offset)
        @offset = offset
        scroll(Library::SCROLL_VIEWPORT_BOTTOM)
        scroll(Library::SCROLL_VIEWPORT_DELTA, -offset) if offset.positive?
      end

      def scroll(tag, delta = 0)
        behavior = Library::ScrollViewport.new
        behavior[:tag] = tag
        behavior[:delta] = delta
        Library.ghostty_terminal_scroll_viewport(terminal, behavior)
      end
    end
  end
end
