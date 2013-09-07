# encoding: utf-8

require 'test/unit'

require 'stringio'

require_relative '../disambiguator'
require_relative '../writers'

class DisambiguatorTest < Test::Unit::TestCase
  def test_token_word_count
    assert_equal(1, TextlabOBTStat::Disambiguator.token_word_count("industrien"))
    assert_equal(2, TextlabOBTStat::Disambiguator.token_word_count("i_hop"))
    assert_equal(3, TextlabOBTStat::Disambiguator.token_word_count("til_og_med"))
  end

  def test_disambiguator
    in_file = StringIO.new("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj \n\t\"hallo\" subst appell nøyt ub ent \n\t\"hallo\" subst appell nøyt ub fl \n<word>i</word>\n\"<i>\"\n\t\"i\" prep \n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>")
    out = StringIO.new
    disamb = TextlabOBTStat::Disambiguator.new(writer: TextlabOBTStat::VRTWriter.new(out),
                                               input_file: in_file)
    assert(disamb)
    disamb.disambiguate
    assert_equal("Hallo\thallo\tinterj\ni\ti\tprep\nluken\tluke\tsubst_appell_mask_be_ent\n.\t$.\t<punkt>".strip,
                 out.string.strip)

  end
end