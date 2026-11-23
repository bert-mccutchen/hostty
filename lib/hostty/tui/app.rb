# frozen_string_literal: true

module Hostty
  module Tui
    class App
      def initialize(stdin:, stdout:, desktop:)
        @stdin = stdin
        @stdout = stdout
        @desktop = desktop
        rows, cols = stdout.winsize
        @layout = Layout.new(rows:, cols:)
        @tabs = Tabs.new
        @clock = Clock.new
      end

      def launch_for(process)
        Pane.new(name: process.name, url: process.url, rows: layout.pane_rows, cols: layout.cols).tap do |pane|
          tabs.add(pane)
        end
      end

      def wait(manager)
        @manager = manager

        tabs.each do |pane|
          pane.subscribe(activity)
        end

        with_terminal do
          cycle until outcome.decided?
        end

        outcome.exit_code
      ensure
        tabs.each(&:discard_output)
      end

      private

      ENTER = "\e[?1049h\e[?1002h\e[?1006h\e[?1004h\e[?25l\e[2J"
      LEAVE = "\e[?1004l\e[?1006l\e[?1002l\e[?2004l\e[?1l\e[0m\e[?25h\e[?1049l"
      private_constant :ENTER, :LEAVE

      attr_reader :stdin, :stdout, :desktop, :layout, :tabs, :clock, :manager

      def with_terminal
        stdin.raw do
          stdout.write(ENTER)
          yield
        ensure
          stdout.write(LEAVE)
        end
      end

      def cycle
        reactor.react(timeout: duties.filter_map(&:wait).min)
        duties.each(&:tick)
      end

      def outcome
        @outcome ||= Outcome.new
      end

      def tab_bar
        @tab_bar ||= Regions::TabBar.new(tabs:, layout:, desktop:)
      end

      def display
        @display ||= Display.new(tab_bar:, tabs:, layout:, manager:)
      end

      def canvas
        @canvas ||= Canvas.new(io: stdout, tabs:, display:, clock:)
      end

      def pointer
        @pointer ||= Mouse::Pointer.new(target: Mouse::Target.new(tabs:, layout:, desktop:, display:), canvas:, clock:)
      end

      def controls
        @controls ||= Controls.new(tabs:, desktop:, pointer:, clock:)
      end

      def activity
        @activity ||= Activity.new(tabs:, canvas:, controls:)
      end

      def duties
        @duties ||= [
          pointer,
          Blink.new(tabs:, tab_bar:, canvas:, clock:),
          Window.new(io: stdout, layout:, tabs:, canvas:),
          canvas
        ]
      end

      def reactor
        @reactor ||= Reactor.new(
          sources: [
            Sources::Stdin.new(io: stdin, controls:, canvas:, outcome:),
            Sources::ManagerEvents.new(manager:, tabs:, canvas:, outcome:),
            *tabs
          ]
        )
      end
    end
  end
end
