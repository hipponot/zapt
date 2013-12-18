gem 'minitest'
require "minitest/autorun"
require_relative '../../lib/zapt/delegator'

class TestZapt < Minitest::Test

  include Zapt::Delegator

  def setup
  end

  def teardown
  end
  
end



