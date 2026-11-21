# frozen_string_literal: true

module Serverb
  class Manager
    class Child
      def initialize(process:, output:, events:)
        @process = process
        @output = output
        @events = events
      end

      def name = process.name

      def start
        reader, writer = IO.pipe
        @pid = spawn_process(writer)
        @reader_thread = Thread.new { forward(reader) }
        Thread.new { events << ProcessExited.new(name:, status: Process.wait2(pid).last) }
      ensure
        writer&.close
      end

      def signal(signal_name)
        return unless pid

        Process.kill(signal_name, -pid)
      rescue Errno::ESRCH, Errno::EPERM
        nil
      end

      def finish
        return unless reader_thread

        reader_thread.kill unless reader_thread.join(OUTPUT_TIMEOUT)
      end

      private

      OUTPUT_TIMEOUT = 2
      private_constant :OUTPUT_TIMEOUT

      attr_reader :process, :output, :events, :pid, :reader_thread

      def spawn_process(writer)
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

      def forward(reader)
        reader.each_line { |text| output.line(name, text.chomp) }
      rescue IOError
        nil
      ensure
        reader.close
      end
    end
  end
end
