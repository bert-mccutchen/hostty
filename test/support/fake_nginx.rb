# frozen_string_literal: true

class FakeNginx
  attr_reader :options

  def initialize(fail_on: nil)
    @fail_on = fail_on
    @options = {}
  end

  def added = options.keys

  def add!(domain_options)
    raise Ruby::Nginx::AbortError, "Declined the sudo prompt." if domain_options[:domain] == fail_on

    options[domain_options[:domain]] = domain_options
  end

  private

  attr_reader :fail_on
end
