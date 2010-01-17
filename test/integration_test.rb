require 'disamb-proto'
require 'test/unit'

class IntegrationTest < Test::Unit::TestCase
  def test_simple_eval
    assert_nothing_raised() { run_disambiguator('test/inputA', 'test/evalA') }
    assert_nothing_raised() { run_disambiguator('test/inputB', 'test/evalB') }
  end
end
