# frozen_string_literal: true

module Serverb
  class Config
    FILE_NAME = ".serverb.yml"
    BASE_PORT = 5000

    def initialize(path:, base_port:)
      @path = File.expand_path(path)
      @base_port = base_port
      validate!
    end

    def processes
      @processes ||=
        data.each_with_index.map do |(name, settings), index|
          ProcessConfig.new(
            name: name.to_s,
            settings:,
            default_port: base_port + (index * PORT_STEP),
            root_path: File.dirname(path)
          )
        end
    end

    private

    PORT_STEP = 100
    private_constant :PORT_STEP

    attr_reader :path, :base_port

    def data
      @data ||= YAML.safe_load_file(path)
    rescue Errno::ENOENT
      raise ConfigError, "No config file at #{path}."
    rescue Psych::Exception => e
      raise ConfigError, "The config file at #{path} is not valid YAML: #{e.message}"
    end

    def validate!
      raise ConfigError, "The config file at #{path} must list at least one process." unless data.is_a?(Hash) && data.any?

      raise_on_duplicates(processes.map(&:port), "port")
      raise_on_duplicates(processes.filter_map(&:domain), "domain")
    end

    def raise_on_duplicates(values, label)
      duplicates = values.tally.select { |_value, count| count > 1 }.keys
      return if duplicates.empty?

      raise ConfigError, "More than one process uses the #{label} #{duplicates.join(", ")}."
    end
  end
end
