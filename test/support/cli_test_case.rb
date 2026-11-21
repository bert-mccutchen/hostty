# frozen_string_literal: true

class CLITestCase < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @stdout = StringIO.new
    @stderr = StringIO.new
    @nginx = FakeNginx.new
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  private

  attr_reader :dir, :stdout, :stderr, :nginx

  def write_config(yaml)
    File.write(config_path, yaml)
  end

  def config_path
    File.join(dir, Serverb::Config::FILE_NAME)
  end

  def serverb(*args, out: stdout, nginx: self.nginx)
    Serverb::CLI.new(argv: ["--file", config_path, *args], nginx:, stdout: out, stderr:).run
  end

  def lines_for(name)
    stdout.string.lines.grep(/ #{name}\s+\| /).map { |line| line.split("| ", 2).last.chomp }
  end
end
