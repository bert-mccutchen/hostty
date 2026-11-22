# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class UniqueDomains
        def initialize(processes:)
          @processes = processes
        end

        def valid? = duplicates.empty?

        def message = "More than one process uses the domain #{duplicates.join(", ")}."

        private

        attr_reader :processes

        def duplicates
          @duplicates ||=
            processes
              .filter_map(&:domain)
              .tally
              .select { |_domain, count| count > 1 }
              .keys
        end
      end
    end
  end
end
