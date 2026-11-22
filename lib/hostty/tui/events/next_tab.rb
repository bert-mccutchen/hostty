# frozen_string_literal: true

module Hostty
  module Tui
    module Events
      class NextTab
        def apply(controls) = controls.select_next
      end
    end
  end
end
