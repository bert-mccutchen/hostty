# frozen_string_literal: true

module Hostty
  class Config
    FILE_NAME = ".hostty.yml"
    BASE_PORT = 5000

    def initialize(path:, base_port:)
      @path = File.expand_path(path)
      @base_port = base_port
      validate!
    end

    def processes
      @processes ||=
        process_data.each_with_index.map do |(name, settings), index|
          ProcessConfig.new(
            name: name.to_s,
            settings:,
            default_port: base_port + (index * PORT_STEP),
            root_path: File.dirname(path),
            ports: port_chooser
          )
        end
    end

    def notices = port_chooser.notices

    private

    PORT_STEP = 100
    KEYS = %w[processes skip_used_ports].freeze
    private_constant :PORT_STEP, :KEYS

    attr_reader :path, :base_port

    def data
      @data ||= YAML.safe_load_file(path)
    rescue Errno::ENOENT
      raise ConfigError, "No config file at #{path}."
    rescue Psych::Exception => e
      raise ConfigError, "The config file at #{path} is not valid YAML: #{e.message}"
    end

    def process_data = data["processes"]

    def skip_used_ports = data.fetch("skip_used_ports", false)

    def port_chooser
      @port_chooser ||= PortChooser.new(skip_used_ports:)
    end

    def validate!
      validate_shape!
      raise ConfigError, "skip_used_ports must be true or false." unless [true, false].include?(skip_used_ports)

      processes.partition(&:fixed_port?).flatten.each(&:port)
      raise_on_duplicate_domains
    end

    def validate_shape!
      raise ConfigError, "The config file at #{path} must be a list of settings." unless data.is_a?(Hash)
      raise ConfigError, "The config file at #{path} must list at least one process under processes." unless process_data.is_a?(Hash) && process_data.any?
      raise ConfigError, "The config file at #{path} has unknown settings: #{unknown_keys.join(", ")}." if unknown_keys.any?
    end

    def unknown_keys
      data.keys.map(&:to_s) - KEYS
    end

    def raise_on_duplicate_domains
      duplicates = processes.filter_map(&:domain).tally.select { |_domain, count| count > 1 }.keys
      return if duplicates.empty?

      raise ConfigError, "More than one process uses the domain #{duplicates.join(", ")}."
    end
  end
end
