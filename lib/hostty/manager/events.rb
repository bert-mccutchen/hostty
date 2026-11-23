# frozen_string_literal: true

module Hostty
  class Manager
    class Events
      attr_reader :wakeup_io

      def initialize
        @queue = Thread::Queue.new
        @wakeup_io, @wakeup_writer = IO.pipe
      end

      def push(event)
        queue << event
        wakeup_writer.write_nonblock(".", exception: false)
      end

      def pop(timeout: nil)
        queue.pop(timeout:)&.tap do
          wakeup_io.read_nonblock(1, exception: false)
        end
      end

      private

      attr_reader :queue, :wakeup_writer
    end
  end
end
