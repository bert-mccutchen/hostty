# frozen_string_literal: true

require "test_helper"

class CLITuiTest < CLITestCase
  def setup
    super
    @driver = TuiDriver.new(rows: 12, cols: 100)
    @desktop = FakeDesktop.new
  end

  def teardown
    @run&.kill&.join
    @driver&.close
    super
  end

  def test_shows_a_tab_per_process_and_switches_tabs_on_a_click
    write_config(<<~YAML)
      processes:
        web: "echo web ready; exec sleep 30"
        jobs: "echo jobs ready; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web ready")
    assert_includes driver.row_text(0), "jobs"

    driver.click("jobs")
    driver.wait_for_text("jobs ready")
    refute_includes driver.screen_text, "web ready"

    assert_equal 0, quit
  end

  def test_scrolls_and_keeps_selecting_while_the_drag_holds_above_the_output
    write_config(<<~YAML)
      processes:
        web: "i=1; while [ $i -le 100 ]; do echo line $i; i=$((i+1)); done; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("line 100")
    driver.press(*driver.position_of("line 95"))
    driver.move_to(0, 0)

    driver.wait_for_text("Scrolled up 5")
    driver.release(0, 0)

    copy = desktop.next_copy
    assert_includes copy, "line 90\nline 91"
    assert copy.end_with?("line 94\nl")
    assert driver.cell(1, 0).style.inverse
    assert_equal 0, quit
  end

  def test_shows_the_url_of_the_selected_process_and_opens_it_on_a_click
    write_config(<<~YAML)
      processes:
        web:
          command: "echo web ready; exec sleep 30"
          domain: "shop.test"
          ssl: true
        jobs: "echo jobs ready; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web ready")
    assert driver.row_text(0).end_with?("https://shop.test")

    driver.click("https://shop.test")
    driver.click("jobs")
    driver.wait_for_text("jobs ready")
    assert_equal ["https://shop.test"], desktop.opened
    refute_includes driver.row_text(0), "shop.test"

    assert_equal 0, quit
  end

  def test_cycles_through_the_tabs_with_shift_tab
    write_config(<<~YAML)
      processes:
        web: "echo web ready; exec sleep 30"
        jobs: "echo jobs ready; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web ready")

    driver.type("\e[Z")
    driver.wait_for_text("jobs ready")

    driver.type("\e[Z")
    driver.wait_for_text("web ready")
    assert_equal 0, quit
  end

  def test_sends_typed_text_to_the_selected_process
    write_config(<<~YAML)
      processes:
        web: "exec cat"
    YAML

    start_tui
    driver.wait_for_text("Quit: Ctrl-C twice")
    driver.type("hello\r")

    driver.wait_for_text("hello", count: 2)
    assert_equal 0, quit
  end

  def test_scrolls_back_through_older_output_with_the_mouse_wheel
    write_config(<<~YAML)
      processes:
        web: "i=1; while [ $i -le 100 ]; do echo line $i; i=$((i+1)); done; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("line 100")
    driver.scroll_back(10)

    driver.wait_for_text("Scrolled up 30")
    assert_includes driver.screen_text, "line 65"
    refute_includes driver.screen_text, "line 100"
    assert_equal 0, quit
  end

  def test_copies_and_highlights_the_text_dragged_across
    write_config(<<~YAML)
      processes:
        web: "echo first line; echo second line; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("second line")
    start = driver.position_of("first line")
    row, col = driver.position_of("second")
    driver.drag(from: start, to: [row, col + 5])

    assert_equal "first line\nsecond", desktop.next_copy
    driver.wait_for_highlight(*start)
    refute driver.cell(row, col + 7).style.inverse
    assert_equal 0, quit
  end

  def test_sends_the_mouse_wheel_to_a_program_that_asks_for_the_mouse
    write_config(<<~'YAML')
      processes:
        btop: >-
          exec ruby -rio/console -e 'STDOUT.sync = true;
          print "\e[?1000h\e[?1006hready\r\n";
          STDIN.raw { loop { print STDIN.readpartial(100).inspect, "\r\n" } }'
    YAML

    start_tui
    driver.wait_for_text("ready")
    driver.scroll_back(1)

    driver.wait_for_text("<64;5;4M")
    assert_includes driver.row_text(11), "Scroll: history"
    assert_equal 0, quit
  end

  def test_sends_arrow_keys_for_the_mouse_wheel_on_the_alternate_screen
    write_config(<<~'YAML')
      processes:
        less: >-
          exec ruby -rio/console -e 'STDOUT.sync = true;
          print "\e[?1049hready\r\n";
          STDIN.raw { loop { print STDIN.readpartial(100).inspect, "\r\n" } }'
    YAML

    start_tui
    driver.wait_for_text("ready")
    driver.scroll_back(1)

    driver.wait_for_text('\e[A\e[A\e[A')
    assert_equal 0, quit
  end

  def test_marks_an_exited_process_and_restarts_it_on_a_click
    write_config(<<~YAML)
      processes:
        web: "echo started; exit 3"
        jobs: "exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web exited with code 3")
    assert_equal 1, driver.cell(0, 1).style.fg

    driver.click_help("[restart]")
    driver.wait_for_text("started", count: 2)
    assert_equal 0, quit
  end

  def test_marks_a_tab_yellow_on_a_bell_until_it_is_selected
    write_config(<<~YAML)
      processes:
        web: "echo web ready; exec sleep 30"
        jobs: "sleep 0.5; printf 'jobs ready\\\\a'; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web ready")
    dot = driver.row_text(0).index("jobs") - 2

    driver.wait_for_color(0, dot, 3)
    assert_equal 0, desktop.rings

    driver.click("jobs")
    driver.wait_for_color(0, dot, 2)
    assert_equal 0, quit
  end

  def test_rings_the_terminal_bell_while_the_window_is_out_of_focus
    write_config(<<~YAML)
      processes:
        web: "echo web ready; exec sleep 30"
        jobs: "sleep 1; printf 'jobs ready\\\\a'; exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("web ready")
    driver.type("\e[O")

    driver.wait_for_color(0, driver.row_text(0).index("jobs") - 2, 3)
    assert_equal 1, desktop.rings
    assert_equal 0, quit
  end

  def test_sends_focus_changes_to_a_program_that_asks_for_them
    write_config(<<~'YAML')
      processes:
        vim: >-
          exec ruby -rio/console -e 'STDOUT.sync = true;
          print "\e[?1004hready\r\n";
          STDIN.raw { loop { print STDIN.readpartial(100).inspect, "\r\n" } }'
    YAML

    start_tui
    driver.wait_for_text("ready")
    driver.type("\e[O")

    driver.wait_for_text('"\e[O"')
    assert_equal 0, quit
  end

  def test_sends_one_ctrl_c_to_the_selected_process
    write_config(<<~YAML)
      processes:
        irb: "exec ruby -e 'require \\"irb\\"; IRB.send(:easter_egg, :dancing)'"
    YAML

    start_tui
    driver.wait_for_text("Press Ctrl+C to stop")
    driver.type("\x03")

    driver.wait_for_text("irb exited with code 0")
    assert_equal 0, quit
  end

  def test_stops_every_process_and_leaves_the_tabs_on_ctrl_c_twice
    write_config(<<~YAML)
      processes:
        web: "exec sleep 30"
    YAML

    start_tui
    driver.wait_for_text("Quit: Ctrl-C twice")

    assert_equal 0, quit
    driver.wait_for_text("Stopping all processes.")
    refute_includes driver.screen_text, "Quit: Ctrl-C twice"
  end

  def test_quits_on_ctrl_c_twice_while_a_process_floods_its_output
    write_config(<<~YAML)
      processes:
        web: "exec yes dancing"
    YAML

    start_tui
    driver.wait_for_text("dancing")

    assert_equal 0, quit
    driver.wait_for_text("Stopping all processes.")
  end

  private

  attr_reader :driver, :desktop

  def start_tui
    @run = Thread.new do
      Hostty::CLI.new(
        argv: hostty_argv("--timeout", "2"),
        nginx:,
        desktop:,
        stdin: driver.terminal,
        stdout: driver.terminal,
        stderr:
      ).run
    end
  end

  def quit
    driver.type("\x03\x03")
    @run.value
  end
end
