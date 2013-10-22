gem 'minitest'
require "minitest/autorun"
require_relative '../../lib/zapt/system'
require_relative '../../lib/zapt/capture_stdout'

class TestZapt < Minitest::Test

  def setup
  end

  def teardown
  end
  
  def test_system
    out = capture_stdout { Zapt.system_stream_stdout('echo foo') }
    assert_equal(out.string.chomp, 'foo')
  end

end



