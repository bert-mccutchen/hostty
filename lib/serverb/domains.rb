# frozen_string_literal: true

module Serverb
  class Domains
    def initialize(processes:, nginx:, output:)
      @processes = processes.select(&:domain)
      @nginx = nginx
      @output = output
      @added = []
    end

    def add
      processes.each { |process| add_domain(process) }
    rescue StandardError, Interrupt
      remove
      raise
    end

    def remove
      remove_domain(added.pop) until added.empty?
    end

    private

    attr_reader :processes, :nginx, :output, :added

    def add_domain(process)
      output.notice("Adding #{process.url} for #{process.name} on port #{process.port}.")
      nginx.add!(process.nginx_options)
      added << process
    end

    def remove_domain(process)
      output.notice("Removing #{process.url}.")
      nginx.remove!(process.nginx_options)
    rescue Ruby::Nginx::Error => e
      output.notice("Could not remove #{process.url}: #{e.message}")
    end
  end
end
