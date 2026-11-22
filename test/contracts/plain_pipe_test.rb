# frozen_string_literal: true

require "test_helper"

class PlainPipeContractTest < ContractTestCase
  include LauncherContract

  private

  def launcher
    @launcher ||= Hostty::Plain::Pipe.new(output: Hostty::Output.new(names: ["web"], io: StringIO.new))
  end
end
