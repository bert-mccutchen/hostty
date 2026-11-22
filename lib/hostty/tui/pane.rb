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
        @bell = Bell.new
        @screen = Ghostty::Screen.new(rows:, cols:, reply: pty, bell:)
        @lifecycle = Lifecycle.new(name:, screen:)
        @offset = 0
      end

      def running? = lifecycle.running?

      def bell? = bell.ringing?

      def io = pty.reader

      def subscribe(listener)
        @listener = listener
      end

      def start(process)
        lifecycle.start
        pty.start(process, rows:, cols:)
      end

      def finish
        pty.close
      end

      def read
        listener.output(self) if pull
        bell.relay(listener)
      end

      def exited(exit_code, manager:)
        nil while pull && io
        lifecycle.exited(exit_code, manager:)
        bell.relay(listener)
      end

      def restart(manager)
        lifecycle.restart(manager)
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

      def clear_bell
        bell.silence
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

      attr_reader :rows, :cols, :pty, :bell, :lifecycle, :listener, :selection

      def selecting?
        !selection.nil? && !selection.empty?
      end

      def pull
        data = pty.read
        screen.feed(data) if data
        !data&.empty?
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
    end
  end
end
