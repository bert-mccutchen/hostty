# frozen_string_literal: true

module Hostty
  class Config
    class Loader
      class ProcessDefinition
        def initialize(name:, settings:, default_port:, root_path:)
          @name = name
          @settings = settings
          @default_port = default_port
          @root_path = root_path
        end

        def fixed_port? = settings["port"].is_a?(Integer)

        def validate!
          Validator.call(Rules::ProcessSettings.new(name:, settings:))
          Validator.call(
            Rules::KnownSettings.new(owner: name, settings:, allowed: KEYS),
            Rules::Command.new(name:, command: settings["command"]),
            Rules::PortSetting.new(name:, port: preferred_port),
            Rules::Domain.new(name:, domain: settings["domain"]),
            Rules::PathSettings.new(name:, settings:),
            Rules::Env.new(name:, env: settings.fetch("env", {}))
          )
        end

        def choose_port(port_chooser)
          port_chooser.choose(name:, preferred: preferred_port, movable: !fixed_port?)
        end

        def build(port:)
          ProcessConfig.new(name:, settings:, port:, root_path:)
        end

        def self.parse(name:, settings:, default_port:, root_path:)
          new(
            name:,
            settings: settings.is_a?(String) ? {"command" => settings} : settings,
            default_port:,
            root_path:
          )
        end

        private

        KEYS = %w[command domain port ssl log host root template env].freeze
        private_constant :KEYS

        attr_reader :name, :settings, :default_port, :root_path

        def preferred_port = settings.fetch("port", default_port)
      end
    end
  end
end
