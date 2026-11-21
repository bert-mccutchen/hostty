# frozen_string_literal: true

module Serverb
  class Output
    def initialize(names:, io:)
      @io = io
      @width = [*names, NOTICE_NAME].map(&:length).max
      @colors = names.each_with_index.to_h { |name, index| [name, COLORS[index % COLORS.size]] }
      @mutex = Mutex.new
    end

    def line(name, text)
      prefix = "#{Time.now.strftime("%H:%M:%S")} #{name.ljust(width)} |"

      mutex.synchronize { io.puts("#{colorize(prefix, colors.fetch(name, NOTICE_COLOR))} #{text}") }
    end

    def notice(text)
      line(NOTICE_NAME, text)
    end

    private

    COLORS = [36, 33, 32, 35, 34, 31].freeze
    NOTICE_NAME = "serverb"
    NOTICE_COLOR = 37
    private_constant :COLORS, :NOTICE_NAME, :NOTICE_COLOR

    attr_reader :io, :width, :colors, :mutex

    def colorize(text, color)
      return text unless io.tty?

      "\e[#{color}m#{text}\e[0m"
    end
  end
end
