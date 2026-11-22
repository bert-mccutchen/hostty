# frozen_string_literal: true

module LauncherContract
  def teardown
    stop_child
    launcher.finish unless @finished
    super
  end

  def test_start_returns_the_pid_of_a_child_process_that_exits
    pid = launcher.start(process)

    assert_kind_of Integer, pid
    assert_predicate reap(pid), :success?
  end

  def test_start_makes_the_child_the_leader_of_its_own_process_group
    pid = launcher.start(process)
    reap(pid)

    assert_equal pid.to_s, report.first
  end

  def test_start_gives_the_child_the_process_environment_with_its_port
    reap(launcher.start(process))

    assert_equal [process.port.to_s, "blue"], report.drop(1)
  end

  def test_finish_releases_the_threads_and_descriptors_after_the_child_exits
    launcher
    threads = Thread.list.size
    descriptors = open_descriptors
    reap(launcher.start(process))

    finish

    assert_operator Thread.list.size, :<=, threads
    assert_operator open_descriptors, :<=, descriptors
  end

  private

  def process
    @process ||= load_process(
      "command" => %(echo $(ps -o pgid= -p $$) $PORT $COLOR > "#{report_path}"),
      "env" => {"COLOR" => "blue"}
    )
  end

  def report_path
    File.join(dir, "report")
  end

  def report
    File.read(report_path).split
  end

  def reap(pid)
    @pid = pid
    Process.wait2(pid).last.tap { @pid = nil }
  end

  def finish
    @finished = true
    launcher.finish
  end

  def open_descriptors
    Dir.children("/dev/fd").size
  end

  def stop_child
    return unless @pid

    Process.kill("KILL", -@pid)
    Process.wait(@pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  end
end
