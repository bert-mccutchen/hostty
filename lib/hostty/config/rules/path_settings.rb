# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class PathSettings
        def initialize(name:, settings:)
          @name = name
          @settings = settings
        end

        def valid? = invalid_keys.empty?

        def message = "#{name} needs a text value for its #{invalid_keys.join(" and ")}."

        private

        KEYS = %w[root template].freeze
        private_constant :KEYS

        attr_reader :name, :settings

        def invalid_keys
          @invalid_keys ||= KEYS.select do |key|
            settings.key?(key) && !Text.new(settings[key]).present?
          end
        end
      end
    end
  end
end
