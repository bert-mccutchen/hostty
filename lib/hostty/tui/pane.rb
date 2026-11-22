# frozen_string_literal: true

module Hostty
  module Tui
    class Pane
      attr_reader :name, :url, :screen, :offset

      def initialize(name:, url:, rows:, cols:)
        @name = name
        @url = url
        @rows = rows
        @cols = cols
        @pty = Pty.new
        @screen = Ghostty::Screen.new(rows:, cols:, reply: pty, bell: method(:ring))
        @offset = 0
        @running = false
        @bell = false
        @rang = false
      end

      def running? = @running

      def bell? = @bell

      def io = pty.reader

      def start(process)
        notify("\e[2m[hostty] Starting #{name}.") if @exit_code
        @exit_code = nil
        @running = true
        pty.start(process, rows:, cols:)
      end

      def finish
        pty.close
      end

      def read
        data = pty.read
        screen.feed(data) if data
        !data&.empty?
      end

      def write(data)
        @offset = 0
        @selection = nil
        pty.write(data)
      end

      def send_focus(focused)
        pty.write(focused ? "\e[I" : "\e[O") if screen.focus_events?
      end

      def send_mouse(event)
        bytes = screen.encode_mouse(event)
        write(bytes) unless bytes.empty?
      end

      def select_from(row:, col:)
        @selection = Selection.new(anchor: [history_row(row), col])
      end

      def select_to(row:, col:)
        @selection = selection&.to([history_row(row), col])
      end

      def selected_columns(row, width)
        selection.columns(history_row(row), width) if selecting?
      end

      def selected_text
        selection.text(history_lines(selection.rows)) if selecting?
      end

      def exited(exit_code)
        nil while read && io
        @exit_code = exit_code
        @running = false
        notify("\e[31m[hostty] #{name} exited with code #{exit_code}.")
      end

      def request_restart
        @restart_requested = true
      end

      def take_restart_request
        @restart_requested.tap { @restart_requested = false }
      end

      def take_ring
        @rang.tap { @rang = false }
      end

      def clear_bell
        @bell = false
      end

      def scroll(lines)
        @offset = (offset + lines).clamp(0, screen.scrollback_size)
      end

      def lines
        screen.lines(offset:)
      end

      def resize(rows:, cols:)
        @rows = rows
        @cols = cols
        screen.resize(rows:, cols:)
        pty.resize(rows:, cols:)
        @selection = nil
        scroll(0)
      end

      private

      attr_reader :rows, :cols, :pty, :selection

      def selecting?
        !selection.nil? && !selection.empty?
      end

      def history_row(row)
        screen.scrollback_size - offset + row
      end

      def history_lines(range)
        size = screen.scrollback_size

        range.step(rows).each_with_object({}) do |first, lines|
          page_offset = (size - first).clamp(0, size)
          screen.lines(offset: page_offset).each_with_index { |cells, index| lines[size - page_offset + index] = cells }
        end
      end

      def ring
        @bell = true
        @rang = true
      end

      def notify(text)
        screen.feed("\e[0m\r\n#{text}\e[0m\r\n")
      end
    end
  end
end
