# frozen_string_literal: true

module Hostty
  module Tui
    class Lifecycle
      class Running
        def running? = true

        def start(_lifecycle) = nil

        def exited(lifecycle, manager:) = lifecycle.become(Exited.new)

        def restart(lifecycle, manager)
          lifecycle.become(Restarting.new)
          manager.terminate(lifecycle.name)
        end
      end
    end
  end
end
