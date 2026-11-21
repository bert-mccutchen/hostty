# frozen_string_literal: true

module Serverb
  class CLI
    def initialize(argv:, nginx: Ruby::Nginx, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @nginx = nginx
      @stdout = stdout
      @stderr = stderr
    end

    def run
      arguments = parser.parse(argv, into: options)
      return print_and_succeed(parser.help) if options[:help]
      return print_and_succeed(VERSION) if options[:version]
      raise OptionParser::InvalidArgument, arguments.join(" ") unless arguments.empty? || arguments == ["start"]

      start
    rescue OptionParser::ParseError, Error, Ruby::Nginx::Error => e
      stderr.puts("serverb: #{e.message}")
      1
    rescue Interrupt
      130
    end

    private

    attr_reader :argv, :nginx, :stdout, :stderr

    def options
      @options ||= {
        file: Config::FILE_NAME,
        port: Config::BASE_PORT,
        timeout: 10
      }
    end

    def parser
      @parser ||= OptionParser.new do |parser|
        parser.banner = "Usage: serverb [start] [options]"
        parser.on("-f", "--file FILE", "Read the processes from FILE. Defaults to #{Config::FILE_NAME}.")
        parser.on("-p", "--port PORT", Integer, "Give the first process PORT. Defaults to #{Config::BASE_PORT}.")
        parser.on("-t", "--timeout SECONDS", Float, "Wait SECONDS for the processes to stop before killing them.")
        parser.on("-v", "--version", "Print the version.")
        parser.on("-h", "--help", "Print this help.")
      end
    end

    def config
      @config ||= Config.new(path: options[:file], base_port: options[:port])
    end

    def output
      @output ||= Output.new(names: config.processes.map(&:name), io: stdout)
    end

    def domains
      @domains ||= Domains.new(processes: config.processes, nginx:, output:)
    end

    def start
      domains.add
      run_processes
    end

    def run_processes
      Manager.new(processes: config.processes, output:, stop_timeout: options[:timeout]).run
    ensure
      domains.remove
    end

    def print_and_succeed(text)
      stdout.puts(text)
      0
    end
  end
end
