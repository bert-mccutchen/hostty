# frozen_string_literal: true

module Hostty
  module Tui
    class Desktop
      def initialize(io:)
        @io = io
      end

      def copy(text)
        io.write("\e]52;c;#{[text].pack("m0")}\a")
        copy_with_command(text)
      end

      def open(url)
        Process.detach(Process.spawn(OPENER, url, out: File::NULL, err: File::NULL))
      rescue SystemCallError
        nil
      end

      private

      OPENER = RUBY_PLATFORM.include?("darwin") ? "open" : "xdg-open"
      CLIPBOARD_COMMANDS = [
        %w[pbcopy],
        %w[wl-copy],
        %w[xclip -selection clipboard],
        %w[xsel --clipboard --input]
      ].freeze
      private_constant :OPENER, :CLIPBOARD_COMMANDS

      attr_reader :io

      def copy_with_command(text)
        return unless clipboard_command

        IO.popen(clipboard_command, "w", err: File::NULL) { |pipe| pipe.write(text) }
      rescue SystemCallError, IOError
        nil
      end

      def clipboard_command
        @clipboard_command ||= CLIPBOARD_COMMANDS.find { |command| installed?(command.first) }
      end

      def installed?(name)
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
      end
    end
  end
end
