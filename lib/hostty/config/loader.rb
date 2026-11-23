# frozen_string_literal: true

module Hostty
  class Config
    class Loader
      def initialize(path:, base_port:)
        @path = File.expand_path(path)
        @base_port = base_port
      end

      def call
        validate_file!
        definitions.each(&:validate!)
        Validator.call(Rules::UniqueDomains.new(processes:))
        Config.new(processes:, notices: port_chooser.notices)
      end

      def self.call(...) = new(...).call

      private

      PORT_STEP = 100
      KEYS = %w[processes skip_used_ports].freeze
      private_constant :PORT_STEP, :KEYS

      attr_reader :path, :base_port

      def process_data = data["processes"]

      def skip_used_ports = data.fetch("skip_used_ports", false)

      def data
        @data ||= YAML.safe_load_file(path)
      rescue Errno::ENOENT
        raise ConfigError, "No config file at #{path}."
      rescue Psych::Exception => e
        raise ConfigError, "The config file at #{path} is not valid YAML: #{e.message}"
      end

      def validate_file!
        Validator.call(Rules::SettingsList.new(data:, path:))
        Validator.call(
          Rules::ProcessList.new(processes: process_data, path:),
          Rules::KnownSettings.new(owner: "The config file at #{path}", settings: data, allowed: KEYS)
        )
        Validator.call(Rules::SkipUsedPorts.new(skip_used_ports:))
      end

      def definitions
        @definitions ||=
          process_data.each_with_index.map do |(name, settings), index|
            ProcessDefinition.parse(
              name: name.to_s,
              settings:,
              default_port: base_port + (index * PORT_STEP),
              root_path: File.dirname(path)
            )
          end
      end

      def port_chooser
        @port_chooser ||= PortChooser.new(skip_used_ports:)
      end

      def ports
        @ports ||=
          definitions
            .partition(&:fixed_port?)
            .flatten
            .to_h { |definition| [definition, definition.choose_port(port_chooser)] }
      end

      def processes
        @processes ||=
          definitions.map do |definition|
            definition.build(port: ports.fetch(definition))
          end
      end
    end
  end
end
