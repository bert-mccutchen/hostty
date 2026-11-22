# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class Command
        def initialize(name:, command:)
          @name = name
          @command = command
        end

        def valid? = Text.new(command).present?

        def message = "#{name} needs a command."

        private

        attr_reader :name, :command
      end
    end
  end
end
