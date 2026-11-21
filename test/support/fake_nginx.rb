# frozen_string_literal: true

class FakeNginx
  attr_reader :calls

  def initialize(fail_on: nil)
    @fail_on = fail_on
    @calls = []
  end

  def add!(options)
    raise Ruby::Nginx::AbortError, "Declined the sudo prompt." if options[:domain] == fail_on

    calls << [:add, options[:domain]]
  end

  def remove!(options)
    calls << [:remove, options[:domain]]
  end

  private

  attr_reader :fail_on
end
