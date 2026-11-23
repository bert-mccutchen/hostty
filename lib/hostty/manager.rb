# frozen_string_literal: true

module Hostty
  class Manager
    def initialize(processes:, front_end:, output:, stop_timeout:)
      @front_end = front_end
      @output = output
      @stop_timeout = stop_timeout
      @events = Events.new
      @children =
        processes.to_h do |process|
          [process.name, build_child(process)]
        end

      @running = {}
    end

    def wakeup_io = events.wakeup_io

    def run
      with_signal_traps do
        children.each_key do |name|
          start(name)
        end

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

    def running_names = running.keys.join(", ")

    def build_child(process)
      Child.new(process:, launch: front_end.launch_for(process), events:)
    end

    def trap_signal(signal)
      trap(signal) do
        events.push(SignalReceived.new(signal:))
      end
    end

    def with_signal_traps
      previous_handlers = SIGNALS.to_h do |signal|
        [signal, trap_signal(signal)]
      end

      yield
    ensure
      previous_handlers&.each do |signal, handler|
        trap(signal, handler || "DEFAULT")
      end
    end

    def receive(timeout: nil)
      next_event(timeout:)&.tap do |event|
        event.announce(output)
      end
    end

    def stop
      unless running.empty?
        output.notice("Stopping all processes.")
        signal_children("TERM")
        kill_children unless wait_for_children(timeout: stop_timeout, hint: "Press Ctrl-C to send KILL now.")
      end

      children.each_value(&:finish)
    end

    def wait_for_children(timeout:, hint:)
      countdown = Countdown.new(seconds: timeout)

      until running.empty?
        event = receive(timeout: countdown.next_wait)
        return false if event&.interrupt?
        next if event
        return false if countdown.expired?

        countdown.remind do |seconds|
          output.notice("Waiting for #{running_names}, #{seconds_left(seconds)}. #{hint}")
        end
      end

      true
    end

    def kill_children
      output.notice("Killing #{running_names}.")
      signal_children("KILL")
      return if wait_for_children(timeout: KILL_TIMEOUT, hint: "Press Ctrl-C to stop waiting.")

      output.notice("Stopped waiting. Still running: #{running_names}.")
    end

    def seconds_left(seconds)
      "#{seconds} #{(seconds == 1) ? "second" : "seconds"} left"
    end

    def signal_children(signal_name)
      children.each_value do |child|
        child.signal(signal_name)
      end
    end
  end
end
