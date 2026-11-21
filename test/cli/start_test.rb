# frozen_string_literal: true

require "test_helper"

class CLIStartTest < CLITestCase
  def test_runs_each_process_with_its_port_and_stops_the_rest_when_one_exits
    write_config(<<~YAML)
      web: "echo port=$PORT; exit 3"
      api:
        command: "exec sleep 30"
        port: 9000
    YAML

    assert_equal 3, serverb

    assert_equal ["port=5000"], lines_for("web")
    assert_includes lines_for("serverb"), "web exited with code 3."
    assert_includes lines_for("serverb"), "Stopping all processes."
    assert_includes lines_for("serverb"), "api exited with code 143."
  end

  def test_starts_from_the_port_option_and_passes_the_env_setting
    write_config(<<~YAML)
      web:
        command: "echo port=$PORT color=$COLOR"
        env:
          COLOR: "blue"
    YAML

    assert_equal 0, serverb("--port", "3000")
    assert_equal ["port=3000 color=blue"], lines_for("web")
  end

  def test_adds_domains_before_the_processes_start_and_removes_them_after
    write_config(<<~YAML)
      web:
        command: "echo started"
        domain: "shop.test"
        ssl: true
      worker: "exec sleep 30"
    YAML

    assert_equal 0, serverb

    assert_equal [[:add, "shop.test"], [:remove, "shop.test"]], nginx.calls
    assert_operator stdout.string.index("Adding https://shop.test for web on port 5000."), :<, stdout.string.index("started")
    assert_includes lines_for("serverb"), "Removing https://shop.test."
  end

  def test_removes_added_domains_and_starts_nothing_when_a_domain_fails
    write_config(<<~YAML)
      web:
        command: "echo started"
        domain: "shop.test"
      api:
        command: "echo started"
        domain: "api.shop.test"
    YAML

    assert_equal 1, serverb(nginx: FakeNginx.new(fail_on: "api.shop.test"))

    assert_equal "serverb: Declined the sudo prompt.\n", stderr.string
    refute_includes stdout.string, "started"
    assert_includes lines_for("serverb"), "Removing http://shop.test."
  end

  def test_stops_every_process_and_its_child_processes_on_ctrl_c
    write_config(<<~YAML)
      web: "exec sleep 30"
      worker: "sleep 30 & echo child=$!; wait"
    YAML

    reader, writer = IO.pipe
    writer.sync = true
    run = Thread.new { serverb(out: writer) }
    child_pid = reader.each_line.lazy.filter_map { |line| line[/child=(\d+)/, 1] }.first.to_i

    Process.kill("INT", Process.pid)

    assert_equal 0, run.value
    assert_includes ["", "Z"], process_state(child_pid)
  ensure
    writer&.close
    reader&.close
  end

  def test_reports_a_missing_config_file
    assert_equal 1, serverb

    assert_equal "serverb: No config file at #{config_path}.\n", stderr.string
  end

  def test_reports_an_invalid_process
    write_config(<<~YAML)
      web:
        domain: "shop.test"
    YAML

    assert_equal 1, serverb

    assert_equal "serverb: web needs a command.\n", stderr.string
  end

  def test_reports_two_processes_with_the_same_domain
    write_config(<<~YAML)
      web:
        command: "exec sleep 30"
        domain: "shop.test"
      api:
        command: "exec sleep 30"
        domain: "shop.test"
    YAML

    assert_equal 1, serverb

    assert_equal "serverb: More than one process uses the domain shop.test.\n", stderr.string
  end

  private

  def process_state(pid)
    IO.popen(["ps", "-o", "stat=", "-p", pid.to_s], &:read).strip[0].to_s
  end
end
