require 'test/unit'

require_relative '../globals'

class GlobalsTest < Test::Unit::TestCase

  def test_remove_quotes
    assert_equal('', TextlabOBTStat.remove_quotes('""'))
    assert_equal('"', TextlabOBTStat.remove_quotes('"'))
    assert_equal('fnork', TextlabOBTStat.remove_quotes('fnork'))
    assert_equal('fnork', TextlabOBTStat.remove_quotes('"fnork"'))
    assert_equal('1', TextlabOBTStat.remove_quotes('"1"'))
    assert_equal('1', TextlabOBTStat.remove_quotes('1'))
  end
end