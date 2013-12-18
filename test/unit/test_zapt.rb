gem 'minitest'
require "minitest/autorun"
require_relative '../../lib/zapt'
require_relative '../../lib/zapt/capture_stdout'

class TestZapt < Minitest::Test

  def setup
  end

  def teardown
  end

  def test_message
    out = capture_stdout { 
      $logger = Logger.new($stdout)
      Zapt.message 'hello world' 
    }
    assert(/INFO -- : hello world/ =~ out.string.chomp)
  end

end



