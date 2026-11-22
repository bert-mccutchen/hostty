# frozen_string_literal: true

require "test_helper"

class TuiAppContractTest < ContractTestCase
  include FrontEndContract

  def setup
    super
    @driver = TuiDriver.new(rows: 12, cols: 100)
  end

  def teardown
    super
    @driver.close
  end

  private

  attr_reader :driver

  def front_end
    @front_end ||= Hostty::Tui::App.new(stdin: driver.terminal, stdout: driver.terminal, desktop: FakeDesktop.new)
  end
end
