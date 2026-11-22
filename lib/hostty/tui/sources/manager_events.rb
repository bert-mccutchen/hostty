# frozen_string_literal: true

module Hostty
  module Tui
    module Sources
      class ManagerEvents
        def initialize(manager:, tabs:, canvas:, outcome:)
          @manager = manager
          @tabs = tabs
          @canvas = canvas
          @outcome = outcome
        end

        def io = manager.wakeup_io

        def read
          while (event = manager.next_event(timeout: 0))
            return outcome.decide(event.exit_code) if event.interrupt?

            tabs.named(event.name).exited(event.exit_code, manager:)
            canvas.invalidate
          end
        end

        private

        attr_reader :manager, :tabs, :canvas, :outcome
      end
    end
  end
end
