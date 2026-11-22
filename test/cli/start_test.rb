# frozen_string_literal: true

require "test_helper"

class CLIStartTest < CLITestCase
  def test_runs_each_process_with_its_port_and_stops_the_rest_when_one_exits
    write_config(<<~YAML)
      processes:
        web: "echo port=$PORT; exit 3"
        api: "echo port=$PORT; exec sleep 30"
    YAML

    assert_equal 3, hostty

    assert_equal ["port=#{base_port}"], lines_for("web")
    assert_includes lines_for("hostty"), "web exited with code 3."
    assert_includes lines_for("hostty"), "Stopping all processes."
    assert_includes lines_for("hostty"), "api exited with code 143."
  end

  def test_passes_the_env_setting
    write_config(<<~YAML)
      processes:
        web:
          command: "echo color=$COLOR"
          env:
            COLOR: "blue"
    YAML

    assert_equal 0, hostty
    assert_equal ["color=blue"], lines_for("web")
  end

  def test_adds_domains_before_the_processes_start
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
          ssl: true
        jobs: "exec sleep 30"
    YAML

    assert_equal 0, hostty

    assert_equal ["shop.test"], nginx.added
    assert_operator stdout.string.index("Adding https://shop.test for web on port #{base_port}."), :<, stdout.string.index("started")
  end

  def test_starts_nothing_when_a_domain_fails
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
        docs:
          command: "echo started"
          domain: "docs.shop.test"
    YAML

    assert_equal 1, hostty(nginx: FakeNginx.new(fail_on: "docs.shop.test"))

    assert_equal "hostty: Declined the sudo prompt.\n", stderr.string
    refute_includes stdout.string, "started"
  end

  def test_stops_every_process_and_its_child_processes_on_ctrl_c
    write_config(<<~YAML)
      processes:
        web: "exec sleep 30"
        jobs: "sleep 30 & echo child=$!; wait"
    YAML

    reader, writer = IO.pipe
    writer.sync = true
    run = Thread.new { hostty(out: writer) }
    child_pid = reader.each_line.lazy.filter_map { |line| line[/child=(\d+)/, 1] }.first.to_i

    Process.kill("INT", Process.pid)

    assert_equal 0, run.value
    assert_includes ["", "Z"], process_state(child_pid)
  ensure
    writer&.close
    reader&.close
  end

  def test_reports_a_missing_config_file
    assert_equal 1, hostty

    assert_equal "hostty: No config file at #{config_path}.\n", stderr.string
  end

  def test_reports_a_config_file_without_processes
    write_config(<<~YAML)
      web: "bin/rails server"
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: The config file at #{config_path} must list at least one process under processes.\n", stderr.string
  end

  def test_reports_an_invalid_process
    write_config(<<~YAML)
      processes:
        web:
          domain: "shop.test"
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: web needs a command.\n", stderr.string
  end

  def test_reports_two_processes_with_the_same_domain
    write_config(<<~YAML)
      processes:
        web:
          command: "exec sleep 30"
          domain: "shop.test"
        docs:
          command: "exec sleep 30"
          domain: "shop.test"
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: More than one process uses the domain shop.test.\n", stderr.string
  end

  private

  def process_state(pid)
    IO.popen(["ps", "-o", "stat=", "-p", pid.to_s], &:read).strip[0].to_s
  end
end
