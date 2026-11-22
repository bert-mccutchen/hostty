# frozen_string_literal: true

class FakeDesktop
  attr_reader :opened, :rings

  def initialize
    @copies = Queue.new
    @opened = []
    @rings = 0
  end

  def ring
    @rings += 1
  end

  def copy(text)
    @copies << text
  end

  def open(url)
    opened << url
  end

  def next_copy
    @copies.pop(timeout: TIMEOUT) or raise "Timed out waiting for a copy."
  end

  TIMEOUT = 5
  private_constant :TIMEOUT
end
