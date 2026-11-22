# frozen_string_literal: true

module Hostty
  class NginxTemplate
    def initialize(name:, base_path:)
      @name = name
      @base_path = base_path
    end

    def path
      return File.expand_path("templates/#{name}.conf.erb", __dir__) if built_in?

      File.expand_path(name, base_path)
    end

    def static_root
      root = STATIC_ROOTS[name]
      File.expand_path(root, base_path) if root
    end

    private

    STATIC_ROOTS = {
      "rails" => "public",
      "proxy" => nil
    }.freeze
    private_constant :STATIC_ROOTS

    attr_reader :name, :base_path

    def built_in? = STATIC_ROOTS.key?(name)
  end
end
