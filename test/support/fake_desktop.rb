# frozen_string_literal: true

class FakeDesktop
  attr_reader :opened

  def initialize
    @copies = Queue.new
    @opened = []
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
