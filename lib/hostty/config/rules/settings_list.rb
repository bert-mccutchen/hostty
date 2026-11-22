# frozen_string_literal: true

module Hostty
  class Config
    module Rules
      class SettingsList
        def initialize(data:, path:)
          @data = data
          @path = path
        end

        def valid? = data.is_a?(Hash)

        def message = "The config file at #{path} must be a list of settings."

        private

        attr_reader :data, :path
      end
    end
  end
end
