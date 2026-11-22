# frozen_string_literal: true

module Hostty
  module Plain
    class Pipe
      def initialize(output:)
        @output = output
      end

      def start(process)
        reader, writer = IO.pipe
        pid = spawn_process(process, writer)
        @reader_thread = Thread.new { forward(process.name, reader) }
        pid
      ensure
        writer&.close
      end

      def finish
        return unless reader_thread

        reader_thread.kill unless reader_thread.join(OUTPUT_TIMEOUT)
      end

      private

      OUTPUT_TIMEOUT = 2
      private_constant :OUTPUT_TIMEOUT

      attr_reader :output, :reader_thread

      def spawn_process(process, writer)
        Process.spawn(
          process.environment,
          "/bin/sh",
          "-c",
          process.command,
          chdir: process.root_path,
          pgroup: true,
          in: File::NULL,
          out: writer,
          err: writer
        )
      end

      def forward(name, reader)
        reader.each_line { |text| output.line(name, text.chomp) }
      rescue IOError
        nil
      ensure
        reader.close
      end
    end
  end
end
