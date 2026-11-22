# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class ProcessSettings
        def initialize(name:, settings:)
          @name = name
          @settings = settings
        end

        def valid? = settings.is_a?(Hash)

        def message = "#{name} must be a command or a list of settings."

        private

        attr_reader :name, :settings
      end
    end
  end
end
