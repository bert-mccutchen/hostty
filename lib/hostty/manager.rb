# frozen_string_literal: true

module Hostty
  class Manager
    def initialize(processes:, front_end:, output:, stop_timeout:)
      @front_end = front_end
      @output = output
      @stop_timeout = stop_timeout
      @events = Events.new
      @children = processes.to_h { |process| [process.name, build_child(process)] }
      @running = {}
    end

    def wakeup_io = events.wakeup_io

    def run
      with_signal_traps do
        children.each_key { |name| start(name) }
        front_end.wait(self)
      ensure
        stop
      end
    end

    def next_event(timeout: nil)
      events.pop(timeout:)&.tap do |event|
        running.delete(event.name) unless event.interrupt?
      end
    end

    def start(name)
      return if running.key?(name)

      children.fetch(name).start
      running[name] = true
    end

    def terminate(name)
      children.fetch(name).signal("TERM") if running.key?(name)
    end

    private

    SIGNALS = %w[INT TERM HUP].freeze
    KILL_TIMEOUT = 5
    private_constant :SIGNALS, :KILL_TIMEOUT

    attr_reader :front_end, :output, :stop_timeout, :events, :children, :running

    def build_child(process)
      Child.new(process:, launch: front_end.launch_for(process), events:)
    end

    def with_signal_traps
      previous_handlers = SIGNALS.to_h { |signal| [signal, trap(signal) { events.push(SignalReceived.new(signal:)) }] }
      yield
    ensure
      previous_handlers&.each { |signal, handler| trap(signal, handler || "DEFAULT") }
    end

    def receive(timeout: nil)
      next_event(timeout:)&.tap { |event| event.announce(output) }
    end

    def stop
      unless running.empty?
        output.notice("Stopping all processes.")
        signal_children("TERM")
        kill_children unless wait_for_children(timeout: stop_timeout)
      end

      children.each_value(&:finish)
    end

    def wait_for_children(timeout:)
      deadline = clock + timeout

      until running.empty?
        event = receive(timeout: (deadline - clock).clamp(0, timeout))
        return false if event.nil? || event.interrupt?
      end

      true
    end

    def kill_children
      output.notice("Killing the processes that are still running.")
      signal_children("KILL")
      return if wait_for_children(timeout: KILL_TIMEOUT)

      output.notice("Stopped waiting for #{running.keys.join(", ")}.")
    end

    def signal_children(signal_name)
      children.each_value { |child| child.signal(signal_name) }
    end

    def clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
