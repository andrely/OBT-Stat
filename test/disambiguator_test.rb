require 'disambiguator'
require 'disamb-proto'
require 'test/unit'

class DisambiguatorTest < Test::Unit::TestCase
  def test_token_word_count
    assert_equal(1, Disambiguator.token_word_count("industrien"))
    assert_equal(2, Disambiguator.token_word_count("i_hop"))
    assert_equal(3, Disambiguator.token_word_count("til_og_med"))
  end
end
