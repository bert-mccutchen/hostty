# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class ProcessList
        def initialize(processes:, path:)
          @processes = processes
          @path = path
        end

        def valid?
          processes.is_a?(Hash) && processes.any?
        end

        def message = "The config file at #{path} must list at least one process under processes."

        private

        attr_reader :processes, :path
      end
    end
  end
end
