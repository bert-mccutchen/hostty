# frozen_string_literal: true

module Hostty
  module Tui
    module Sources
      class Stdin
        attr_reader :io

        def initialize(io:, controls:, canvas:, outcome:)
          @io = io
          @controls = controls
          @canvas = canvas
          @outcome = outcome
          @input = Input.new
        end

        def read
          data = io.read_nonblock(4096, exception: false)
          return if data == :wait_readable
          return outcome.decide(0) unless data

          input.parse(data).each { |event| event.apply(controls) }
          outcome.decide(0) if controls.quit?
          canvas.invalidate
        end

        private

        attr_reader :controls, :canvas, :outcome, :input
      end
    end
  end
end
