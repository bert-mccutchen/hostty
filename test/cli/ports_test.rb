# frozen_string_literal: true

require "test_helper"

class CLIPortsTest < CLITestCase
  def test_stops_when_a_port_is_in_use
    write_config(<<~YAML)
      processes:
        web: "echo started"
    YAML

    hold_port(base_port) do
      assert_equal 1, hostty
    end

    assert_equal "hostty: Port #{base_port} for web is in use. Free the port, or set skip_used_ports to true.\n", stderr.string
    refute_includes stdout.string, "started"
  end

  def test_moves_to_the_next_free_port_when_skipping_used_ports
    write_config(<<~YAML)
      skip_used_ports: true
      processes:
        web: "echo port=$PORT"
    YAML

    hold_port(base_port) do
      assert_equal 0, hostty
    end

    assert_includes lines_for("hostty"), "Port #{base_port} for web is in use. web uses #{base_port + 1}."
    assert_equal ["port=#{base_port + 1}"], lines_for("web")
  end

  def test_moves_past_a_port_held_on_localhost_only
    write_config(<<~YAML)
      skip_used_ports: true
      processes:
        web: "echo port=$PORT"
    YAML

    hold_port(base_port, host: "127.0.0.1") do
      hold_port(base_port + 1, host: "::1") do
        assert_equal 0, hostty
      end
    end

    assert_equal ["port=#{base_port + 2}"], lines_for("web")
  end

  def test_never_moves_a_port_set_on_the_process
    write_config(<<~YAML)
      skip_used_ports: true
      processes:
        web:
          command: "echo started"
          port: #{base_port + 200}
    YAML

    hold_port(base_port + 200) do
      assert_equal 1, hostty
    end

    assert_equal "hostty: Port #{base_port + 200} for web is in use. Free the port, or change the port of web.\n", stderr.string
  end

  def test_gives_a_set_port_first_claim_over_a_position_port
    write_config(<<~YAML)
      skip_used_ports: true
      processes:
        web:
          command: "true"
          domain: "shop.test"
        docs:
          command: "true"
          domain: "docs.shop.test"
          port: #{base_port}
    YAML

    assert_equal 0, hostty

    assert_includes lines_for("hostty"), "Adding http://shop.test for web on port #{base_port + 1}."
    assert_includes lines_for("hostty"), "Adding http://docs.shop.test for docs on port #{base_port}."
  end

  def test_reports_two_processes_on_one_port
    write_config(<<~YAML)
      processes:
        web: "echo started"
        docs:
          command: "echo started"
          port: #{base_port}
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: docs and web both use port #{base_port}.\n", stderr.string
  end

  def test_picks_a_random_port
    write_config(<<~YAML)
      processes:
        web:
          command: "echo port=$PORT"
          port: "random"
    YAML

    assert_equal 0, hostty

    assert_includes 10_000..59_999, lines_for("web").first.delete_prefix("port=").to_i
  end

  def test_reports_a_skip_used_ports_setting_that_is_not_true_or_false
    write_config(<<~YAML)
      skip_used_ports: "yes please"
      processes:
        web: "echo started"
    YAML

    assert_equal 1, hostty

    assert_equal "hostty: skip_used_ports must be true or false.\n", stderr.string
  end
end
