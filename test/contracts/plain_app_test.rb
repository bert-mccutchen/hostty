# frozen_string_literal: true

require "test_helper"

class PlainAppContractTest < ContractTestCase
  include FrontEndContract

  private

  def front_end
    @front_end ||= Hostty::Plain::App.new(output: Hostty::Output.new(names: ["web"], io: StringIO.new))
  end
end
