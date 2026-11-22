# frozen_string_literal: true

module Hostty
  class Domains
    def initialize(processes:, nginx:, output:)
      @processes = processes.select(&:domain)
      @nginx = nginx
      @output = output
    end

    def add
      processes.each do |process|
        output.notice("Adding #{process.url} for #{process.name} on port #{process.port}.")
        nginx.add!(NginxOptions.new(process:).to_h)
      end
    end

    private

    attr_reader :processes, :nginx, :output
  end
end
