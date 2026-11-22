# frozen_string_literal: true

module Hostty
  module Tui
    class Reactor
      def initialize(sources:)
        @sources = sources
      end

      def react(timeout:)
        readable = Array(IO.select(sources.filter_map(&:io), nil, nil, timeout)&.first)
        sources.each { |source| source.read if readable.include?(source.io) }
      end

      private

      attr_reader :sources
    end
  end
end
