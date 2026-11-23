# frozen_string_literal: true

module Hostty
  class Manager
    class Child
      def initialize(process:, launch:, events:)
        @process = process
        @launch = launch
        @events = events
      end

      def name = process.name

      def start
        @pid = launch.start(process)

        Thread.new(pid) do |child_pid|
          events.push(ProcessExited.new(name:, status: Process.wait2(child_pid).last))
        end
      end

      def signal(signal_name)
        return unless pid

        Process.kill(signal_name, -pid)
      rescue Errno::ESRCH, Errno::EPERM
        nil
      end

      def finish
        launch.finish
      end

      private

      attr_reader :process, :launch, :events, :pid
    end
  end
end
