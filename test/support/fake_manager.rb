# frozen_string_literal: true

class FakeManager
  attr_reader :wakeup_io

  def initialize
    @events = Thread::Queue.new
    @wakeup_io, @wakeup_writer = IO.pipe
  end

  def stop(exit_code:)
    events << StopEvent.new(exit_code:)
    wakeup_writer.write(".")
  end

  def next_event(timeout: nil)
    events.pop(timeout:)
  end

  def close
    wakeup_writer.close
    wakeup_io.close
  end

  private

  attr_reader :events, :wakeup_writer
end
