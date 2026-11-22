# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class Env
        def initialize(name:, env:)
          @name = name
          @env = env
        end

        def valid? = env.is_a?(Hash)

        def message = "#{name} needs a list of names and values for its env."

        private

        attr_reader :name, :env
      end
    end
  end
end
