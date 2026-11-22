# frozen_string_literal: true

module Hostty
  module Tui
    class Bell
      def initialize
        @ringing = false
        @rang = false
      end

      def ringing? = @ringing

      def call
        @ringing = true
        @rang = true
      end

      def relay(listener)
        return unless @rang

        @rang = false
        listener.bell
      end

      def silence
        @ringing = false
      end
    end
  end
end
