# frozen_string_literal: true

module Hostty
  module Tui
    class Lifecycle
      class Pending
        def running? = false

        def start(lifecycle) = lifecycle.become(Running.new)

        def restart(lifecycle, manager) = manager.start(lifecycle.name)

        def exited(lifecycle, manager:) = lifecycle.become(Exited.new)
      end
    end
  end
end
