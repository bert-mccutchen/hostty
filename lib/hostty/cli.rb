# frozen_string_literal: true

module Hostty
  class CLI
    def initialize(argv:, nginx: Ruby::Nginx, stdin: $stdin, stdout: $stdout, stderr: $stderr, desktop: nil)
      @argv = argv
      @nginx = nginx
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @desktop = desktop || Tui::Desktop.new(io: stdout)
    end

    def run
      arguments = parser.parse(argv, into: options)
      return print_and_succeed(parser.help) if options[:help]
      return print_and_succeed(VERSION) if options[:version]
      raise OptionParser::InvalidArgument, arguments.join(" ") unless arguments.empty? || arguments == ["start"]

      start
    rescue OptionParser::ParseError, Error, Ruby::Nginx::Error => e
      stderr.puts("hostty: #{e.message}")
      1
    rescue Interrupt
      130
    end

    private

    attr_reader :argv, :nginx, :stdin, :stdout, :stderr, :desktop

    def tui?
      !options[:plain] && stdin.tty? && stdout.tty?
    end

    def options
      @options ||= {
        file: Config::FILE_NAME,
        port: Config::BASE_PORT,
        timeout: 10
      }
    end

    def parser
      @parser ||= OptionParser.new do |parser|
        parser.banner = "Usage: hostty [start] [options]"
        parser.on("-f", "--file FILE", "Read the processes from FILE. Defaults to #{Config::FILE_NAME}.")
        parser.on("-p", "--port PORT", Integer, "Give the first process PORT. Defaults to #{Config::BASE_PORT}.")
        parser.on("-t", "--timeout SECONDS", Float, "Wait SECONDS for the processes to stop before killing them.")
        parser.on("--plain", "Print the output of all processes together instead of in tabs.")
        parser.on("-v", "--version", "Print the version.")
        parser.on("-h", "--help", "Print this help.")
      end
    end

    def config
      @config ||= Config::Loader.call(path: options[:file], base_port: options[:port])
    end

    def output
      @output ||= Output.new(names: config.processes.map(&:name), io: stdout)
    end

    def front_end
      tui? ? Tui::App.new(stdin:, stdout:, desktop:) : Plain::App.new(output:)
    end

    def load_ghostty
      require_relative "ghostty/screen"
    rescue LoadError => e
      raise Error, "Tabs need libghostty-vt, which did not load (#{e.message}). Run with --plain to skip the tabs."
    end

    def start
      load_ghostty if tui?
      config.notices.each { |notice| output.notice(notice) }
      Domains.new(processes: config.processes, nginx:, output:).add
      Manager.new(processes: config.processes, front_end:, output:, stop_timeout: options[:timeout]).run
    end

    def print_and_succeed(text)
      stdout.puts(text)
      0
    end
  end
end
