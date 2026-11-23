# frozen_string_literal: true

require "test_helper"
require "timeout"

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

  def test_passes_the_root_and_template_relative_to_the_config_file
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
          root: "public"
          template: "config/nginx.conf.erb"
        docs:
          command: "echo started"
          domain: "docs.shop.test"
    YAML

    assert_equal 0, hostty

    assert_equal File.join(dir, "public"), nginx.options["shop.test"][:root_path]
    assert_equal File.join(dir, "config/nginx.conf.erb"), nginx.options["shop.test"][:template_path]
    assert_equal dir, nginx.options["docs.shop.test"][:root_path]
    refute nginx.options["docs.shop.test"].key?(:template_path)
  end

  def test_uses_a_built_in_template_by_name
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
          template: "rails"
        docs:
          command: "echo started"
          domain: "docs.shop.test"
          template: "proxy"
    YAML

    assert_equal 0, hostty

    assert_path_exists nginx.options["shop.test"][:template_path]
    assert_equal File.join(dir, "public"), nginx.options["shop.test"][:root_path]
    assert_path_exists nginx.options["docs.shop.test"][:template_path]
    assert_equal dir, nginx.options["docs.shop.test"][:root_path]
  end

  def test_uses_the_root_setting_over_the_root_of_a_built_in_template
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
          template: "rails"
          root: "static"
    YAML

    assert_equal 0, hostty

    assert_equal File.join(dir, "static"), nginx.options["shop.test"][:root_path]
  end

  def test_reports_a_template_that_is_not_text
    write_config(<<~YAML)
      processes:
        web:
          command: "echo started"
          domain: "shop.test"
          template: 3
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: web needs a text value for its template.\n", stderr.string
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

    run = Thread.new do
      hostty(out: writer)
    end

    child_pid =
      reader
        .each_line
        .lazy
        .filter_map do |line|
          line[/child=(\d+)/, 1]
        end
        .first
        .to_i

    Process.kill("INT", Process.pid)

    assert_equal 0, run.value
    assert_includes ["", "Z"], process_state(child_pid)
  ensure
    writer&.close
    reader&.close
  end

  def test_names_the_running_processes_and_kills_them_on_a_second_ctrl_c_during_the_stop
    write_config(<<~YAML)
      processes:
        web: "trap '' TERM; echo ready; while true; do sleep 1; done"
    YAML

    reader, writer, pid = spawn_hostty_in_terminal("--plain", "--timeout", "30")
    read_until(reader, "ready")
    Process.kill("INT", pid)
    read_until(reader, "Stopping all processes.")

    assert_includes read_until(reader, "Press Ctrl-C", timeout: 3), "Waiting for web, 29 seconds left. Press Ctrl-C to send KILL now."
    Process.kill("INT", pid)
    assert_includes read_until(reader, "Killing", timeout: 5), "Killing web."
  ensure
    clean_up_hostty(pid, reader, writer) if pid
  end

  def test_stops_a_process_that_prints_on_term_after_leaving_the_tabs
    write_config(<<~YAML)
      processes:
        web: "trap '' INT; trap 'echo stopping; exit 0' TERM; echo ready; while true; do sleep 1; done"
    YAML

    reader, writer, pid = spawn_hostty_in_terminal("--timeout", "30")
    read_until(reader, "ready")
    writer.write("\x03\x03")

    output = read_until(reader, "web exited with code 0.", timeout: 5)
    assert_includes output, "web exited with code 0."
    refute_includes output, "Killing"
  ensure
    clean_up_hostty(pid, reader, writer) if pid
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

  def lib_path = File.expand_path("../../lib", __dir__)

  def exe_path = File.expand_path("../../exe/hostty", __dir__)

  def spawn_hostty_in_terminal(*args)
    PTY.spawn("/bin/sh", "-c", 'stty rows 24 cols 80; exec "$0" "$@"', RbConfig.ruby, "-I", lib_path, exe_path, *hostty_argv(*args))
  end

  def read_until(reader, text, timeout: 10)
    output = +""

    Timeout.timeout(timeout) do
      until output.include?(text)
        output << reader.readpartial(4096)
      end
    end

    output
  rescue EOFError, Errno::EIO
    output
  end

  def clean_up_hostty(pid, reader, writer)
    kill_session(pid)
    drain(reader)
    Process.wait(pid)
    [reader, writer].each(&:close)
  end

  def kill_session(pid)
    Process.kill("KILL", -pid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  def drain(reader)
    reader.read
  rescue Errno::EIO
    nil
  end

  def process_state(pid)
    IO.popen(["ps", "-o", "stat=", "-p", pid.to_s], &:read).strip[0].to_s
  end
end
