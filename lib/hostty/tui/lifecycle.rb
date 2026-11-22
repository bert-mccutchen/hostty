# frozen_string_literal: true

module Hostty
  module Tui
    class Lifecycle
      attr_reader :name

      def initialize(name:, screen:)
        @name = name
        @screen = screen
        @state = Pending.new
      end

      def running? = state.running?

      def start = state.start(self)

      def restart(manager) = state.restart(self, manager)

      def exited(exit_code, manager:)
        notify("\e[31m[hostty] #{name} exited with code #{exit_code}.")
        state.exited(self, manager:)
      end

      def become(state)
        @state = state
      end

      def notify(text)
        screen.feed("\e[0m\r\n#{text}\e[0m\r\n")
      end

      private

      attr_reader :screen, :state
    end
  end
end
