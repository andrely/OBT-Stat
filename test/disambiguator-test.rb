require 'disamb-proto'
require 'test/unit'

class DisambiguatorTest < Test::Unit::TestCase
  def test_counts_to_indices
    in1 = [1, 1, 1, 1]
    out1 = [0, 1, 2, 3]

    in2 = [1, 2, 1, 1]
    out2 = [0, 1, 1, 2, 3]

    in3 = [2, 1, 1, 2]
    out3 = [0, 0, 1, 2, 3, 3]

    assert_equal(out1, counts_to_indices(in1))
    assert_equal(out2, counts_to_indices(in2))
    assert_equal(out3, counts_to_indices(in3))
  end
end
