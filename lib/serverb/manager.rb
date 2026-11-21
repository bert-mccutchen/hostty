# frozen_string_literal: true

module Serverb
  class Manager
    def initialize(processes:, output:, stop_timeout:)
      @output = output
      @stop_timeout = stop_timeout
      @events = Thread::Queue.new
      @children = processes.map { |process| Child.new(process:, output:, events:) }
      @running = {}
    end

    def run
      with_signal_traps do
        start_children
        receive.exit_code
      ensure
        stop
      end
    end

    private

    SIGNALS = %w[INT TERM HUP].freeze
    private_constant :SIGNALS

    attr_reader :output, :stop_timeout, :events, :children, :running

    def with_signal_traps
      previous_handlers = SIGNALS.to_h { |signal| [signal, trap(signal) { events << SignalReceived.new(signal:) }] }
      yield
    ensure
      previous_handlers&.each { |signal, handler| trap(signal, handler || "DEFAULT") }
    end

    def start_children
      children.each do |child|
        child.start
        running[child.name] = child
      end
    end

    def receive(timeout: nil)
      events.pop(timeout:)&.tap do |event|
        event.announce(output)
        running.delete(event.name) unless event.interrupt?
      end
    end

    def stop
      unless running.empty?
        output.notice("Stopping all processes.")
        signal_children("TERM")
        kill_children unless wait_for_children
      end

      children.each(&:finish)
    end

    def wait_for_children
      deadline = clock + stop_timeout

      until running.empty?
        event = receive(timeout: (deadline - clock).clamp(0, stop_timeout))
        return false if event.nil? || event.interrupt?
      end

      true
    end

    def kill_children
      output.notice("Killing the processes that are still running.")
      signal_children("KILL")
      receive until running.empty?
    end

    def signal_children(signal_name)
      children.each { |child| child.signal(signal_name) }
    end

    def clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
