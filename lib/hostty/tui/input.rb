# frozen_string_literal: true

module Hostty
  module Tui
    class Input
      def initialize
        @pending = +"".b
      end

      def parse(data)
        @pending << data.b
        events = []
        events << next_event until @pending.empty? || incomplete_mouse?
        events.compact
      end

      private

      CTRL_C = "\x03".b
      SHIFT_TAB = "\e[Z".b
      FOCUS_IN = "\e[I".b
      FOCUS_OUT = "\e[O".b
      SPECIAL = /\x03|\e\[<|\e\[[ZIO]/n
      MOUSE = /\A\e\[<(\d+);(\d+);(\d+)([Mm])/n
      INCOMPLETE_MOUSE = /\A\e\[<[\d;]*\z/n
      BUTTONS = [:left, :middle, :right, nil].freeze
      WHEEL_BUTTONS = [:wheel_up, :wheel_down, nil, nil].freeze
      MODIFIER_BITS = {shift: 4, alt: 8, ctrl: 16}.freeze
      private_constant :CTRL_C, :SHIFT_TAB, :FOCUS_IN, :FOCUS_OUT, :SPECIAL, :MOUSE, :INCOMPLETE_MOUSE, :BUTTONS, :WHEEL_BUTTONS, :MODIFIER_BITS

      def incomplete_mouse?
        INCOMPLETE_MOUSE.match?(@pending)
      end

      def next_event
        index = @pending.index(SPECIAL)
        return Events::Keys.new(bytes: take(index || @pending.size)) unless index&.zero?
        return Events::Interrupt.new(bytes: take(1)) if @pending.start_with?(CTRL_C)
        return take(SHIFT_TAB.size) && Events::NextTab.new if @pending.start_with?(SHIFT_TAB)
        return take(FOCUS_IN.size) && Events::Focus.new(focused: true) if @pending.start_with?(FOCUS_IN)
        return take(FOCUS_OUT.size) && Events::Focus.new(focused: false) if @pending.start_with?(FOCUS_OUT)

        match = MOUSE.match(@pending)
        return Events::Keys.new(bytes: take(@pending.size)) unless match

        take(match[0].size)
        mouse_event(match)
      end

      def take(size)
        @pending.slice!(0, size)
      end

      def mouse_event(match)
        code = match[1].to_i
        event = MouseEvent.new(
          action: mouse_action(code, match[4]),
          button: (code.anybits?(64) ? WHEEL_BUTTONS : BUTTONS)[code & 0b11],
          row: match[3].to_i - 1,
          col: match[2].to_i - 1,
          modifiers: mouse_modifiers(code)
        )
        Events::MouseReport.new(mouse: event) if event.button
      end

      def mouse_modifiers(code)
        MODIFIER_BITS.filter_map do |name, bit|
          name if code.anybits?(bit)
        end
      end

      def mouse_action(code, final)
        return :release if final == "m"

        code.anybits?(32) ? :motion : :press
      end
    end
  end
end
