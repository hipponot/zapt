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
    Zapt.message 'hello world'
  end

end



