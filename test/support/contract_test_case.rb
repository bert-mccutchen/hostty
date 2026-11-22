# frozen_string_literal: true

class ContractTestCase < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(dir)
  end

  private

  attr_reader :dir

  def config_path
    File.join(dir, Hostty::Config::FILE_NAME)
  end

  def load_process(settings)
    File.write(config_path, {"skip_used_ports" => true, "processes" => {"web" => settings}}.to_yaml)
    Hostty::Config::Loader.call(path: config_path, base_port: Hostty::Config::BASE_PORT).processes.first
  end
end
