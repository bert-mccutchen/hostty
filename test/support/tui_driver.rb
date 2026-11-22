# frozen_string_literal: true

class TuiDriver
  attr_reader :terminal

  def initialize(rows:, cols:)
    @rows = rows
    @master, @terminal = PTY.open
    @terminal.winsize = [rows, cols]
    @screen = Hostty::Ghostty::Screen.new(rows:, cols:)
    @mutex = Mutex.new
    @changed = ConditionVariable.new
    @reader = Thread.new { read_screen }
  end

  def type(text)
    master.write(text)
  end

  def click(text, row: 0)
    col = row_text(row).index(text) or raise "No #{text.inspect} on row #{row}: #{row_text(row).inspect}"
    master.write("\e[<0;#{col + 1};#{row + 1}M\e[<0;#{col + 1};#{row + 1}m")
  end

  def click_help(text)
    click(text, row: rows - 1)
  end

  def scroll_back(times)
    master.write("\e[<64;5;5M" * times)
  end

  def drag(from:, to:)
    press(*from)
    move_to(*to)
    release(*to)
  end

  def press(row, col)
    master.write("\e[<0;#{col + 1};#{row + 1}M")
  end

  def move_to(row, col)
    master.write("\e[<32;#{col + 1};#{row + 1}M")
  end

  def release(row, col)
    master.write("\e[<0;#{col + 1};#{row + 1}m")
  end

  def position_of(text)
    screen_text.lines.each_with_index do |line, row|
      col = line.index(text)
      return [row, col] if col
    end

    raise "No #{text.inspect} on the screen"
  end

  def wait_for_highlight(row, col)
    wait_until("a highlight at row #{row}, column #{col}") { screen.lines[row][col].style.inverse }
  end

  def wait_for_color(row, col, color)
    wait_until("color #{color} at row #{row}, column #{col}") { screen.lines[row][col].style.fg == color }
  end

  def wait_for_text(text, count: 1)
    wait_until("#{text.inspect} #{count} times") { visible_text.scan(text).size >= count }
  end

  def screen_text
    mutex.synchronize { visible_text }
  end

  def row_text(row)
    screen_text.lines[row].to_s.chomp
  end

  def cell(row, col)
    mutex.synchronize { screen.lines[row][col] }
  end

  def close
    terminal.close
    master.close
    reader.join
  end

  private

  TIMEOUT = 5
  private_constant :TIMEOUT

  attr_reader :rows, :master, :screen, :mutex, :changed, :reader

  def wait_until(description)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT

    mutex.synchronize do
      until yield
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise "Timed out waiting for #{description}. The screen shows:\n#{visible_text}" unless remaining.positive?

        changed.wait(mutex, remaining)
      end
    end
  end

  def visible_text
    screen.lines.map { |cells| cells.map(&:char).join.rstrip }.join("\n")
  end

  def read_screen
    loop do
      data = master.readpartial(4096)
      mutex.synchronize do
        screen.feed(data)
        changed.broadcast
      end
    end
  rescue Errno::EIO, IOError
    nil
  end
end
