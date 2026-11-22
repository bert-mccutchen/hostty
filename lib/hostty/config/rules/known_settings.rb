# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class KnownSettings
        def initialize(owner:, settings:, allowed:)
          @owner = owner
          @settings = settings
          @allowed = allowed
        end

        def valid? = unknown_keys.empty?

        def message = "#{owner} has unknown settings: #{unknown_keys.join(", ")}."

        private

        attr_reader :owner, :settings, :allowed

        def unknown_keys
          @unknown_keys ||= settings.keys.map(&:to_s) - allowed
        end
      end
    end
  end
end
