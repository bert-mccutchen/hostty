# frozen_string_literal: true

module Hostty
  module Tui
    class Lifecycle
      class Exited
        def running? = false

        def restart(lifecycle, manager) = manager.start(lifecycle.name)

        def exited(_lifecycle, manager:) = nil

        def start(lifecycle)
          lifecycle.notify("\e[2m[hostty] Starting #{lifecycle.name}.")
          lifecycle.become(Running.new)
        end
      end
    end
  end
end
