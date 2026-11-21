# frozen_string_literal: true

require "test_helper"

class CLIOptionsTest < CLITestCase
  def test_prints_the_version
    assert_equal 0, serverb("--version")
    assert_equal "#{Serverb::VERSION}\n", stdout.string
  end

  def test_prints_the_help
    assert_equal 0, serverb("--help")
    assert_includes stdout.string, "Usage: serverb [start] [options]"
  end

  def test_rejects_an_unknown_command
    assert_equal 1, serverb("restart")
    assert_equal "serverb: invalid argument: restart\n", stderr.string
  end
end
