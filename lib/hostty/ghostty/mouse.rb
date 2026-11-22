# frozen_string_literal: true

module Hostty
  module Ghostty
    class Mouse
      def initialize(terminal:)
        @terminal = terminal
        @encoder = Library.create(:ghostty_mouse_encoder_new, :ghostty_mouse_encoder_free)
        @event = Library.create(:ghostty_mouse_event_new, :ghostty_mouse_event_free)
      end

      def encode(mouse, rows:, cols:)
        track_buttons(mouse)
        prepare_encoder(rows:, cols:)
        prepare_event(mouse)
        Library.ghostty_mouse_encoder_encode(encoder, event, buffer, BUFFER_SIZE, written)
        buffer.get_bytes(0, written.read(:size_t))
      end

      private

      BUFFER_SIZE = 128
      private_constant :BUFFER_SIZE

      attr_reader :terminal, :encoder, :event

      def track_buttons(mouse)
        return if mouse.wheel?

        @pressed = mouse.action != :release
      end

      def prepare_encoder(rows:, cols:)
        Library.ghostty_mouse_encoder_set_from_terminal(encoder, terminal)
        Library.ghostty_mouse_encoder_set(encoder, Library::MOUSE_ENCODER_OPT_SIZE, size(rows:, cols:))
        pressed = FFI::MemoryPointer.new(:uint8).write_uint8(@pressed ? 1 : 0)
        Library.ghostty_mouse_encoder_set(encoder, Library::MOUSE_ENCODER_OPT_ANY_BUTTON_PRESSED, pressed)
      end

      def size(rows:, cols:)
        Library::MouseEncoderSize.new.tap do |size|
          size[:size] = Library::MouseEncoderSize.size
          size[:screen_width] = cols
          size[:screen_height] = rows
          size[:cell_width] = 1
          size[:cell_height] = 1
        end
      end

      def prepare_event(mouse)
        Library.ghostty_mouse_event_set_action(event, Library::MOUSE_ACTIONS.fetch(mouse.action))
        Library.ghostty_mouse_event_set_button(event, Library::MOUSE_BUTTONS.fetch(mouse.button))
        Library.ghostty_mouse_event_set_mods(event, mods(mouse))
        Library.ghostty_mouse_event_set_position(event, position(mouse))
      end

      def mods(mouse)
        Library::MODS.sum { |name, bit| mouse.public_send(:"#{name}?") ? bit : 0 }
      end

      def position(mouse)
        Library::MousePosition.new.tap do |position|
          position[:x] = mouse.col + 0.5
          position[:y] = mouse.row + 0.5
        end
      end

      def buffer
        @buffer ||= FFI::MemoryPointer.new(:uint8, BUFFER_SIZE)
      end

      def written
        @written ||= FFI::MemoryPointer.new(:size_t)
      end
    end
  end
end
