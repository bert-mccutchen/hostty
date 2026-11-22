# frozen_string_literal: true

module Hostty
  module Terminal
    class Flyweight
      def initialize
        @objects = {}
      end

      def fetch(key)
        @objects.clear if @objects.size > LIMIT
        @objects[key] ||= yield
      end

      LIMIT = 1024
      private_constant :LIMIT
    end
  end
end
