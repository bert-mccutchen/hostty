# frozen_string_literal: true

module Serverb
  class ProcessConfig
    attr_reader :name, :root_path

    def initialize(name:, settings:, default_port:, root_path:)
      @name = name
      @settings = settings.is_a?(String) ? {"command" => settings} : settings
      @default_port = default_port
      @root_path = root_path
      validate!
    end

    def command = settings["command"]

    def domain = settings["domain"]

    def port
      settings.fetch("port", default_port)
    end

    def url
      return unless domain

      "#{settings["ssl"] ? "https" : "http"}://#{domain}"
    end

    def environment
      settings
        .fetch("env", {})
        .to_h { |key, value| [key.to_s, value.to_s] }
        .merge("PORT" => port.to_s)
    end

    def nginx_options
      {
        domain:,
        port:,
        root_path:,
        host: settings["host"],
        ssl: settings["ssl"],
        log: settings["log"]
      }.compact
    end

    private

    KEYS = %w[command domain port ssl log host env].freeze
    private_constant :KEYS

    attr_reader :settings, :default_port

    def validate!
      raise ConfigError, "#{name} must be a command or a list of settings." unless settings.is_a?(Hash)
      raise ConfigError, "#{name} has unknown settings: #{unknown_keys.join(", ")}." if unknown_keys.any?
      raise ConfigError, "#{name} needs a command." unless present_string?(command)
      raise ConfigError, "#{name} needs a whole number for its port." unless port.is_a?(Integer)
      raise ConfigError, "#{name} needs a text value for its domain." unless domain.nil? || present_string?(domain)
      raise ConfigError, "#{name} needs a list of names and values for its env." unless settings.fetch("env", {}).is_a?(Hash)
    end

    def unknown_keys
      settings.keys.map(&:to_s) - KEYS
    end

    def present_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end
  end
end
