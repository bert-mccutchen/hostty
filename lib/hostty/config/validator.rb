# frozen_string_literal: true

module Hostty
  class Config
    class Validator
      def initialize(*rules)
        @rules = rules
      end

      def call
        failure = rules.find { |rule| !rule.valid? }
        raise ConfigError, failure.message if failure
      end

      def self.call(...) = new(...).call

      private

      attr_reader :rules
    end
  end
end
