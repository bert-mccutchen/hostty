# frozen_string_literal: true

module Hostty
  class ProcessConfig
    attr_reader :name, :root_path

    def initialize(name:, settings:, default_port:, root_path:, ports:)
      @name = name
      @settings = settings.is_a?(String) ? {"command" => settings} : settings
      @default_port = default_port
      @root_path = root_path
      @ports = ports
      validate!
    end

    def fixed_port? = settings["port"].is_a?(Integer)

    def command = settings["command"]

    def domain = settings["domain"]

    def port
      @port ||= ports.choose(name:, preferred: settings.fetch("port", default_port), movable: !fixed_port?)
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
        root_path: static_root,
        template_path: template&.path,
        host: settings["host"],
        ssl: settings["ssl"],
        log: settings["log"]
      }.compact
    end

    private

    KEYS = %w[command domain port ssl log host root template env].freeze
    PATH_KEYS = %w[root template].freeze
    PORTS = 1..65_535
    private_constant :KEYS, :PATH_KEYS, :PORTS

    attr_reader :settings, :default_port, :ports

    def validate!
      raise ConfigError, "#{name} must be a command or a list of settings." unless settings.is_a?(Hash)
      raise ConfigError, "#{name} has unknown settings: #{unknown_keys.join(", ")}." if unknown_keys.any?
      raise ConfigError, "#{name} needs a command." unless present_string?(command)
      raise ConfigError, "#{name} needs a port from 1 to 65535, or \"random\"." unless valid_port_setting?
      raise ConfigError, "#{name} needs a text value for its domain." unless domain.nil? || present_string?(domain)
      raise ConfigError, "#{name} needs a text value for its #{invalid_path_keys.join(" and ")}." if invalid_path_keys.any?
      raise ConfigError, "#{name} needs a list of names and values for its env." unless settings.fetch("env", {}).is_a?(Hash)
    end

    def invalid_path_keys
      PATH_KEYS.select { |key| settings.key?(key) && !present_string?(settings[key]) }
    end

    def template
      @template ||= NginxTemplate.new(name: settings["template"], base_path: root_path) if settings["template"]
    end

    def static_root
      return File.expand_path(settings["root"], root_path) if settings["root"]

      template&.static_root || root_path
    end

    def unknown_keys
      settings.keys.map(&:to_s) - KEYS
    end

    def valid_port_setting?
      requested = settings.fetch("port", default_port)
      requested == "random" || (requested.is_a?(Integer) && PORTS.cover?(requested))
    end

    def present_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end
  end
end
