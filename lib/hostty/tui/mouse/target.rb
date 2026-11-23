# frozen_string_literal: true

module Hostty
  module Tui
    module Mouse
      class Target
        def initialize(tabs:, layout:, desktop:, display:)
          @tabs = tabs
          @layout = layout
          @desktop = desktop
          @display = display
        end

        def forward(event)
          return false unless program_mouse?(event)

          selected.send_mouse(event.at(row: event.row - 1))
          true
        end

        def press(event, &)
          display.press(row: event.row, col: event.col, &)
        end

        def drag(event)
          point(event).tap do |point|
            selected.select_to(**point)
          end
        end

        def release(event)
          selected.select_to(**point(event))
          text = selected.selected_text
          desktop.copy(text) if text
        end

        def wheel(event, pointer: nil)
          up = event.button == :wheel_up
          return selected.write(arrow_key(up) * SCROLL_LINES) if selected.screen.alternate_screen?

          selected.scroll(up ? SCROLL_LINES : -SCROLL_LINES)
          selected.select_to(**pointer) if pointer
        end

        def autoscroll(lines:, pointer:)
          selected.scroll(lines)
          selected.select_to(**pointer)
        end

        def direction(event)
          if event.row < 1
            1
          elsif event.row > layout.pane_rows
            -1
          end
        end

        private

        SCROLL_LINES = 3
        private_constant :SCROLL_LINES

        attr_reader :tabs, :layout, :desktop, :display

        def selected = tabs.selected

        def point(event) = layout.pane_point(row: event.row, col: event.col)

        def program_mouse?(event)
          !event.shift? && layout.pane_row?(event.row) && selected.screen.mouse_tracking?
        end

        def arrow_key(up)
          prefix = selected.screen.application_cursor_keys? ? "\eO" : "\e["
          "#{prefix}#{up ? "A" : "B"}"
        end
      end
    end
  end
end
