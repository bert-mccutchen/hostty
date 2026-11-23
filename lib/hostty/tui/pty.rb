# frozen_string_literal: true

module Hostty
  module Tui
    class Pty
      attr_reader :reader

      def start(process, rows:, cols:)
        close
        @reader, @writer, pid = PTY.spawn(
          process.environment,
          "/bin/sh",
          "-c",
          'cd "$1" && exec /bin/sh -c "$2"',
          "hostty",
          process.root_path,
          process.command
        )
        resize(rows:, cols:)
        pid
      end

      def read
        return unless reader

        data = reader.read_nonblock(READ_SIZE, exception: false)
        return "" if data == :wait_readable

        close unless data
        data
      rescue Errno::EIO, IOError
        close
        nil
      end

      def write(data)
        writer&.write_nonblock(data, exception: false)
      rescue Errno::EIO, Errno::EPIPE, IOError
        nil
      end

      def resize(rows:, cols:)
        reader&.winsize = [rows, cols]
      rescue Errno::EIO, Errno::ENOTTY, IOError
        nil
      end

      def discard
        if reader
          Thread.new(reader) do |io|
            discard_until_closed(io)
          end
        end
      end

      def close
        [reader, writer].compact.reject(&:closed?).each(&:close)
        @reader = nil
        @writer = nil
      end

      private

      READ_SIZE = 65_536
      private_constant :READ_SIZE

      attr_reader :writer

      def discard_until_closed(io)
        nil while io.readpartial(READ_SIZE)
      rescue Errno::EIO, IOError
        nil
      end
    end
  end
end
