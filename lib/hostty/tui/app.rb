# frozen_string_literal: true

module Hostty
  module Tui
    class App
      def initialize(stdin:, stdout:, desktop:)
        @stdin = stdin
        @stdout = stdout
        @desktop = desktop
        @rows, @cols = stdout.winsize
        @panes = []
        @selected = 0
        @input = Input.new
        @renderer = Renderer.new(io: stdout)
        @outer_modes = {}
      end

      def launch_for(process)
        Pane.new(name: process.name, url: process.url, rows: rows - 2, cols:).tap { |pane| panes << pane }
      end

      def wait(manager)
        with_terminal do
          until @exit_code
            wait_for_io(manager)
            autoscroll_when_due
            check_size
            render_when_due
          end
        end

        @exit_code
      end

      private

      FRAME_SECONDS = 0.016
      IDLE_SECONDS = 0.25
      DOUBLE_PRESS_SECONDS = 0.5
      SCROLL_LINES = 3
      AUTOSCROLL_SECONDS = 0.025
      AUTOSCROLL_SPEEDUP_SECONDS = 0.5
      AUTOSCROLL_MAX_LINES = 10
      ENTER = "\e[?1049h\e[?1002h\e[?1006h\e[?25l\e[2J"
      LEAVE = "\e[?1006l\e[?1002l\e[?2004l\e[?1l\e[0m\e[?25h\e[?1049l"
      OUTER_MODES = {application_cursor_keys?: 1, bracketed_paste?: 2004}.freeze
      private_constant :FRAME_SECONDS, :IDLE_SECONDS, :DOUBLE_PRESS_SECONDS, :SCROLL_LINES, :AUTOSCROLL_SECONDS, :AUTOSCROLL_SPEEDUP_SECONDS, :AUTOSCROLL_MAX_LINES, :ENTER, :LEAVE, :OUTER_MODES

      attr_reader :stdin, :stdout, :desktop, :rows, :cols, :panes, :input, :renderer

      def selected = panes[@selected]

      def layout
        @layout ||= Layout.new(names: panes.map(&:name), rows:, cols:)
      end

      def with_terminal
        stdin.raw do
          stdout.write(ENTER)
          @dirty = true
          yield
        ensure
          stdout.write(LEAVE)
        end
      end

      def wait_for_io(manager)
        readable, = IO.select([stdin, manager.wakeup_io, *panes.filter_map(&:io)], nil, nil, select_timeout)
        Array(readable).each { |io| handle(io, manager) }
      end

      def handle(io, manager)
        if io == stdin
          read_input(manager)
        elsif io == manager.wakeup_io
          read_events(manager)
        else
          read_output(panes.find { |pane| pane.io == io })
        end
      end

      def read_input(manager)
        data = stdin.read_nonblock(4096, exception: false)
        return if data == :wait_readable
        return quit unless data

        input.parse(data).each { |event| apply(event, manager) }
        @dirty = true
      end

      def apply(event, manager)
        case event
        in [:interrupt, bytes]
          interrupt(bytes)
        in [:next_tab]
          @selected = (@selected + 1) % panes.size
        in [:keys, bytes]
          selected.write(bytes)
        in [:mouse, mouse]
          handle_mouse(mouse, manager)
        end
      end

      def handle_mouse(mouse, manager)
        return selected.send_mouse(mouse.at(row: mouse.row - 1)) if program_mouse?(mouse)
        return wheel(mouse) if mouse.wheel?
        return unless mouse.button == :left

        case mouse.action
        when :press
          click(mouse.row, mouse.col, manager)
        when :motion
          drag(mouse) if @selecting
        when :release
          finish_selection(mouse.row, mouse.col) if @selecting
        end
      end

      def program_mouse?(mouse)
        !@selecting && !mouse.shift? && pane_row?(mouse.row) && selected.screen.mouse_tracking?
      end

      def pane_row?(row) = (1..layout.pane_rows).cover?(row)

      def drag(mouse)
        @pointer = pane_point(mouse.row, mouse.col)
        direction = autoscroll_direction(mouse.row)
        @autoscroll_started_at = clock unless direction == @autoscroll
        @autoscroll = direction
        selected.select_to(**@pointer)
      end

      def autoscroll_direction(row)
        if row < 1
          1
        elsif row > layout.pane_rows
          -1
        end
      end

      def autoscroll_when_due
        return unless @selecting && @autoscroll && clock - @autoscrolled_at.to_f >= AUTOSCROLL_SECONDS

        @autoscrolled_at = clock
        selected.scroll(@autoscroll * autoscroll_lines)
        selected.select_to(**@pointer)
        @dirty = true
      end

      def autoscroll_lines
        (1 + ((clock - @autoscroll_started_at) / AUTOSCROLL_SPEEDUP_SECONDS).floor).clamp(1, AUTOSCROLL_MAX_LINES)
      end

      def wheel(mouse)
        up = mouse.button == :wheel_up
        return selected.write(arrow_key(up) * SCROLL_LINES) if selected.screen.alternate_screen?

        selected.scroll(up ? SCROLL_LINES : -SCROLL_LINES)
        selected.select_to(**@pointer) if @selecting && @pointer
      end

      def arrow_key(up)
        prefix = selected.screen.application_cursor_keys? ? "\eO" : "\e["
        "#{prefix}#{up ? "A" : "B"}"
      end

      def finish_selection(row, col)
        @selecting = false
        @autoscroll = nil
        selected.select_to(**pane_point(row, col))
        copy_selection
      end

      def pane_point(row, col)
        {row: (row - 1).clamp(0, layout.pane_rows - 1), col: col.clamp(0, cols - 1)}
      end

      def copy_selection
        text = selected.selected_text
        desktop.copy(text) if text
      end

      def interrupt(bytes)
        return quit if @interrupted_at && clock - @interrupted_at <= DOUBLE_PRESS_SECONDS

        @interrupted_at = clock
        selected.write(bytes)
      end

      def click(row, col, manager)
        index = layout.tab_at(row:, col:)
        return @selected = index if index
        return desktop.open(selected.url) if layout.url_at?(row:, col:, url: selected.url)
        return restart(selected, manager) if layout.restart_at?(row:, col:, offset: selected.offset)

        return unless pane_row?(row)

        @selecting = true
        @pointer = pane_point(row, col)
        selected.select_from(**@pointer)
      end

      def restart(pane, manager)
        return manager.start(pane.name) unless pane.running?

        pane.request_restart
        manager.terminate(pane.name)
      end

      def read_events(manager)
        while (event = manager.next_event(timeout: 0))
          return @exit_code = event.exit_code if event.interrupt?

          pane = panes.find { |candidate| candidate.name == event.name }
          pane.exited(event.exit_code)
          manager.start(pane.name) if pane.take_restart_request
          @dirty = true
        end
      end

      def read_output(pane)
        return unless pane

        @dirty = true if pane.read && pane.equal?(selected)
      end

      def quit
        @exit_code = 0
      end

      def check_size
        size = stdout.winsize
        return if size == [rows, cols]

        @rows, @cols = size
        @layout = nil
        panes.each { |pane| pane.resize(rows: rows - 2, cols:) }
        renderer.reset
        @dirty = true
      end

      def render_when_due
        return unless @dirty && frame_due?

        sync_outer_modes
        renderer.render(layout:, panes:, selected:)
        @dirty = false
        @rendered_at = clock
      end

      def frame_due?
        @rendered_at.nil? || clock - @rendered_at >= FRAME_SECONDS
      end

      def select_timeout
        return AUTOSCROLL_SECONDS if @selecting && @autoscroll && !@dirty
        return IDLE_SECONDS unless @dirty

        [FRAME_SECONDS - (clock - (@rendered_at || 0)), 0].max
      end

      def sync_outer_modes
        OUTER_MODES.each do |query, mode|
          enabled = selected.screen.public_send(query)
          next if @outer_modes[mode] == enabled

          stdout.write("\e[?#{mode}#{enabled ? "h" : "l"}")
          @outer_modes[mode] = enabled
        end
      end

      def clock
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
