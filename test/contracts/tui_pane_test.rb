# frozen_string_literal: true

require "test_helper"

class TuiPaneContractTest < ContractTestCase
  include LauncherContract

  private

  def launcher
    @launcher ||= Hostty::Tui::Pane.new(name: "web", url: nil, rows: 24, cols: 80)
  end
end
