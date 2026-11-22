# frozen_string_literal: true

module Hostty
  class PortChooser
    attr_reader :notices

    def initialize(skip_used_ports:, random: Random.new)
      @skip_used_ports = skip_used_ports
      @random = random
      @owners = {}
      @notices = []
    end

    def choose(name:, preferred:, movable:)
      port = (preferred == "random") ? random.rand(RANDOM_PORTS) : preferred
      return claim(port, name) if free?(port)
      raise ConfigError, clash_message(name, port, movable:) unless movable && skip_used_ports

      moved = next_free_port(name, port)
      notices << "Port #{port} for #{name} is in use. #{name} uses #{moved}."
      claim(moved, name)
    end

    private

    RANDOM_PORTS = 10_000..59_999
    MOVE_LIMIT = 100
    private_constant :RANDOM_PORTS, :MOVE_LIMIT

    attr_reader :skip_used_ports, :random, :owners

    def free?(port)
      !owners.key?(port) && !in_use?(port)
    end

    def in_use?(port)
      TCPServer.new("0.0.0.0", port).close
      false
    rescue Errno::EADDRINUSE, Errno::EACCES
      true
    end

    def claim(port, name)
      owners[port] = name
      port
    end

    def next_free_port(name, port)
      candidates = (port + 1)..(port + MOVE_LIMIT)
      candidates.find { |candidate| free?(candidate) } or
        raise ConfigError, "No free port for #{name} from #{candidates.begin} to #{candidates.end}."
    end

    def clash_message(name, port, movable:)
      owner = owners[port]
      return "#{owner} and #{name} both use port #{port}." if owner
      return "Port #{port} for #{name} is in use. Free the port, or change the port of #{name}." unless movable

      "Port #{port} for #{name} is in use. Free the port, or set skip_used_ports to true."
    end
  end
end
