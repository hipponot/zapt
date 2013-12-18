gem 'minitest'
require "minitest/autorun"
require_relative '../../lib/zapt'
require_relative '../../lib/zapt/capture_stdout'

class TestRuntask < Minitest::Test

  attr_accessor :taskfile

  def setup
    $logger.level = Logger::FATAL
    @taskfile = File.join(File.dirname(__FILE__), "tasks.rb")
  end

  def teardown

  end

  def test_exit_status_fail
    cmd = "zapt runtask -t #{taskfile} -r shell_fail"
    status = system(cmd) 
    assert_equal(false, status)
  end

  def test_exit_status_succeed
    cmd = "zapt runtask -t #{taskfile} -r shell_succeed"
    status = system(cmd) 
    assert_equal(true, status)
  end

end



