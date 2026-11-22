# frozen_string_literal: true

module Hostty
  class Domains
    class NginxOptions
      def initialize(process:)
        @process = process
      end

      def to_h
        {
          domain: process.domain,
          port: process.port,
          root_path: static_root,
          template_path: template&.path,
          host: process.host,
          ssl: process.ssl,
          log: process.log
        }.compact
      end

      private

      attr_reader :process

      def template
        @template ||= NginxTemplate.new(name: process.template, base_path: process.root_path) if process.template
      end

      def static_root
        return File.expand_path(process.root, process.root_path) if process.root

        template&.static_root || process.root_path
      end
    end
  end
end
