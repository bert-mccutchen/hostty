# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class Domain
        def initialize(name:, domain:)
          @name = name
          @domain = domain
        end

        def valid?
          domain.nil? || Text.new(domain).present?
        end

        def message = "#{name} needs a text value for its domain."

        private

        attr_reader :name, :domain
      end
    end
  end
end
