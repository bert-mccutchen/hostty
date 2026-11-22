# frozen_string_literal: true

class StopEvent
  attr_reader :exit_code

  def initialize(exit_code:)
    @exit_code = exit_code
  end

  def interrupt? = true

  def announce(output)
    output.notice("Stopped with code #{exit_code}.")
  end
end
