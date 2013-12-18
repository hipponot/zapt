gem 'minitest'
require "minitest/autorun"
require_relative '../../lib/zapt/system'
require_relative '../../lib/zapt/capture_stdout'

class TestZapt < Minitest::Test

  def setup
  end

  def teardown
  end
  
  def test_system_status
    # succeeds
    stdout, status = Zapt.system('true',nil,nil,true) 
    assert_equal(status, true)
    # fails 
    stdout, status = Zapt.system('false',nil,nil,true) 
    assert_equal(status, false)
  end

  def test_system_rval
    # succeeds
    stdout, status = Zapt.system('echo foo',nil,nil,true) 
    assert_equal(stdout.chomp, 'foo')
    assert_equal(stdout.chomp, 'foo')
  end

end



