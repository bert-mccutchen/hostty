# frozen_string_literal: true

module Hostty
  class ProcessConfig
    attr_reader :name, :port, :root_path

    def initialize(name:, settings:, port:, root_path:)
      @name = name
      @settings = settings
      @port = port
      @root_path = root_path
    end

    def command = settings["command"]

    def domain = settings["domain"]

    def ssl = settings["ssl"]

    def host = settings["host"]

    def log = settings["log"]

    def root = settings["root"]

    def template = settings["template"]

    def url
      return unless domain

      "#{ssl ? "https" : "http"}://#{domain}"
    end

    def environment
      settings
        .fetch("env", {})
        .to_h { |key, value| [key.to_s, value.to_s] }
        .merge("PORT" => port.to_s)
    end

    private

    attr_reader :settings
  end
end
