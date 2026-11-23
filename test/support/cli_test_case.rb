# frozen_string_literal: true

class CLITestCase < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @stdout = StringIO.new
    @stderr = StringIO.new
    @nginx = FakeNginx.new
    @base_port = free_port
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  private

  attr_reader :dir, :stdout, :stderr, :nginx, :base_port

  def write_config(yaml)
    File.write(config_path, yaml)
  end

  def config_path
    File.join(dir, Hostty::Config::FILE_NAME)
  end

  def hostty_argv(*args)
    ["--file", config_path, "--port", base_port.to_s, *args]
  end

  def hostty(*args, out: stdout, nginx: self.nginx)
    Hostty::CLI.new(argv: hostty_argv(*args), nginx:, stdout: out, stderr:).run
  end

  def lines_for(name)
    stdout
      .string
      .lines
      .grep(/ #{name}\s+\| /)
      .map do |line|
        line.split("| ", 2).last.chomp
      end
  end

  def free_port
    loop do
      port = rand(20_000..40_000)
      return port if every_used_port_bindable?(port)
    end
  end

  def every_used_port_bindable?(port)
    [port, port + 1, port + 100, port + 200].all? do |candidate|
      bindable?(candidate)
    end
  end

  def bindable?(port)
    TCPServer.new("0.0.0.0", port).close
    true
  rescue Errno::EADDRINUSE
    false
  end

  def hold_port(port, host: "0.0.0.0")
    server = TCPServer.new(host, port)
    yield
  ensure
    server&.close
  end
end
