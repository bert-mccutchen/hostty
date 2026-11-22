# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "hostty"
require "hostty/ghostty/screen"

require "minitest/autorun"
require "stringio"
require "tmpdir"

require_relative "support/fake_nginx"
require_relative "support/fake_desktop"
require_relative "support/cli_test_case"
require_relative "support/tui_driver"
