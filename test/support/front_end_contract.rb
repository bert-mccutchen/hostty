# frozen_string_literal: true

module FrontEndContract
  def teardown
    @waiter&.kill&.join
    launchers.each(&:finish)
    @manager&.close
    super
  end

  def test_launch_for_returns_a_launcher
    launcher = launch

    assert_respond_to launcher, :start
    assert_respond_to launcher, :finish
  end

  def test_wait_returns_the_exit_code_of_a_stop_event
    launch
    manager.stop(exit_code: 7)
    @waiter = Thread.new { front_end.wait(manager) }

    assert @waiter.join(WAIT_TIMEOUT), "wait did not return after a stop event."
    assert_equal 7, @waiter.value
  end

  private

  WAIT_TIMEOUT = 5
  private_constant :WAIT_TIMEOUT

  def manager
    @manager ||= FakeManager.new
  end

  def launchers
    @launchers ||= []
  end

  def launch
    front_end.launch_for(load_process("command" => "exec sleep 30")).tap { |launcher| launchers << launcher }
  end
end
