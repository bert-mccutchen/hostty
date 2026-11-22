# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class Text
        def initialize(value)
          @value = value
        end

        def present?
          value.is_a?(String) && !value.strip.empty?
        end

        private

        attr_reader :value
      end
    end
  end
end
