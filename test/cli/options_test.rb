# frozen_string_literal: true

require "test_helper"

class CLIOptionsTest < CLITestCase
  def test_prints_the_version
    assert_equal 0, hostty("--version")
    assert_equal "#{Hostty::VERSION}\n", stdout.string
  end

  def test_prints_the_help
    assert_equal 0, hostty("--help")
    assert_includes stdout.string, "Usage: hostty [start] [options]"
  end

  def test_rejects_an_unknown_command
    assert_equal 1, hostty("restart")
    assert_equal "hostty: invalid argument: restart\n", stderr.string
  end
end
