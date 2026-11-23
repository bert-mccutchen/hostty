# frozen_string_literal: true

require "test_helper"

class GhosttyScreenTest < Minitest::Test
  def setup
    @replies = StringIO.new
    @screen = Hostty::Ghostty::Screen.new(rows: 4, cols: 10, reply: @replies)
  end

  def test_prints_text_and_moves_to_new_lines
    feed("hello\r\nworld")

    assert_equal ["hello", "world", "", ""], text
    assert_equal [1, 5], @screen.cursor
  end

  def test_wraps_at_the_last_column_only_when_the_next_character_prints
    feed("0123456789")

    assert_equal [0, 9], @screen.cursor

    feed("a")

    assert_equal ["0123456789", "a", "", ""], text
  end

  def test_moves_the_cursor_and_erases
    feed("abcdef\e[1;3H\e[K")
    feed("\e[2;1Hxyz\e[2D\e[1P")

    assert_equal ["ab", "xz", "", ""], text
  end

  def test_erases_the_display_and_redraws_a_line_like_reline
    feed("> 1 + 22\e[2J\e[H\r> 1 + 2\e[0K")

    assert_equal ["> 1 + 2", "", "", ""], text
  end

  def test_keeps_lines_that_scroll_off_the_top_as_scrollback
    numbered_lines =
      (1..6)
        .map do |number|
          "line #{number}"
        end
        .join("\r\n")

    feed(numbered_lines)

    assert_equal ["line 3", "line 4", "line 5", "line 6"], text
    assert_equal 2, @screen.scrollback_size
    assert_equal ["line 1", "line 2", "line 3", "line 4"], text(offset: 2)
  end

  def test_scrolls_only_inside_the_scroll_region
    feed("top\r\na\r\nb\r\nbottom\e[2;3r\e[3;1H\nc")

    assert_equal ["top", "b", "c", "bottom"], text
    assert_equal 0, @screen.scrollback_size
  end

  def test_applies_colors_and_attributes
    feed("\e[1;31mred\e[0m \e[38;5;208morange\e[48;2;1;2;3mx")

    first_line, second_line = @screen.lines
    assert_equal Hostty::Terminal::Style.new(fg: 1, bold: true), first_line[0].style
    assert_equal Hostty::Terminal::Style.plain, first_line[3].style
    assert_equal 208, first_line[4].style.fg
    assert_equal [1, 2, 3], second_line[0].style.bg
  end

  def test_applies_strikethrough_overline_blink_and_invisible_text
    feed("\e[9ma\e[0;53mb\e[0;5mc\e[0;8md")

    styles = @screen.lines.first.first(4).map(&:style)
    assert_equal [true, false, false, false], styles.map(&:strikethrough)
    assert_equal [false, true, false, false], styles.map(&:overline)
    assert_equal [false, false, true, false], styles.map(&:blink)
    assert_equal [false, false, false, true], styles.map(&:invisible)
  end

  def test_fills_an_erased_line_with_the_background_color
    feed("\e[44m\e[K\e[0m")

    backgrounds =
      @screen.lines.first.map do |cell|
        cell.style.bg
      end

    assert_equal [4] * 10, backgrounds
  end

  def test_switches_to_the_alternate_screen_and_back
    feed("main\e[?1049halt")

    assert_equal ["    alt", "", "", ""], text

    feed("\e[?1049l")

    assert_equal ["main", "", "", ""], text
    assert_equal [0, 4], @screen.cursor
  end

  def test_answers_cursor_position_and_device_attribute_queries
    feed("ab\e[6n\e[c")

    assert_equal "\e[1;3R\e[?62;22c", @replies.string
  end

  def test_tracks_the_modes_that_change_key_input
    feed("\e[?1h\e[?2004h\e[?25l")

    assert @screen.application_cursor_keys?
    assert @screen.bracketed_paste?
    assert_nil @screen.cursor
  end

  def test_puts_wide_characters_in_two_cells
    feed("a日b")

    assert_equal "a日b", text.first
    assert_equal [0, 4], @screen.cursor
  end

  def test_clears_the_other_half_of_a_wide_character_that_text_overwrites
    feed("日本\e[1;2Hx")

    assert_equal " x本", text.first

    feed("y")

    assert_equal " xy", text.first
  end

  def test_wraps_a_long_line_across_several_rows
    feed("a" * 25)

    assert_equal ["a" * 10, "a" * 10, "a" * 5, ""], text
    assert_equal [2, 5], @screen.cursor
  end

  def test_applies_an_escape_code_split_across_reads
    feed("\e[3")
    feed("1mred")

    assert_equal 1, @screen.lines.first[0].style.fg
  end

  def test_joins_utf8_characters_split_across_reads
    feed("caf\xC3".b)
    feed("\xA9!".b)

    assert_equal "café!", text.first
  end

  def test_drops_title_and_other_string_sequences
    feed("\e]0;my title\aok\e]8;;http://example.com\e\\link")

    assert_equal "oklink", text.first
  end

  def test_calls_the_bell_for_each_bel_character
    rings = 0
    screen = Hostty::Ghostty::Screen.new(rows: 4, cols: 10, bell: -> { rings += 1 })
    screen.feed("a\ab\a")

    assert_equal 2, rings
  end

  def test_reflows_wrapped_lines_after_a_resize
    feed("1234567890\r\nsecond")
    @screen.resize(rows: 2, cols: 4)

    assert_equal ["seco", "nd"], text
    assert_equal ["5678", "90"], text(offset: 2)
  end

  private

  def feed(data)
    @screen.feed(data)
  end

  def text(offset: 0)
    @screen
      .lines(offset:)
      .map do |cells|
        cells.map(&:char).join.rstrip
      end
  end
end
