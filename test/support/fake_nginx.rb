# frozen_string_literal: true

class FakeNginx
  attr_reader :added

  def initialize(fail_on: nil)
    @fail_on = fail_on
    @added = []
  end

  def add!(options)
    raise Ruby::Nginx::AbortError, "Declined the sudo prompt." if options[:domain] == fail_on

    added << options[:domain]
  end

  private

  attr_reader :fail_on
end
