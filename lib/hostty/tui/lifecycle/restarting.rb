# frozen_string_literal: true

module Hostty
  module Tui
    class Lifecycle
      class Restarting
        def running? = true

        def start(_lifecycle) = nil

        def restart(lifecycle, manager) = manager.terminate(lifecycle.name)

        def exited(lifecycle, manager:)
          lifecycle.become(Exited.new)
          manager.start(lifecycle.name)
        end
      end
    end
  end
end
