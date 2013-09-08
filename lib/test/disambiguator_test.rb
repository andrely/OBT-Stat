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

    # "til sjøs" is combined by the multitagger
    in_file = StringIO.new("<word>Vi</word>\n\"<vi>\"\n\t\"vi\" pron fl pers hum nom 1 \n<word>drar</word>\n\"<drar>\"\n\t\"dra\" verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9 \n<word>til sjøs</word>\n\"<til sjøs>\"\n\t\"til sjøs\" prep prep+subst @adv \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt> \n")
    out = StringIO.new
    disamb = TextlabOBTStat::Disambiguator.new(writer: TextlabOBTStat::VRTWriter.new(out),
                                               input_file: in_file)
    assert(disamb)
    disamb.disambiguate
    assert_equal("Vi\tvi\tpron_fl_pers_hum_nom_1\ndrar\tdra\tverb_pres\ntil sjøs\ttil sjøs\tprep_prep+subst_@adv\n.\t$.\t<punkt>".strip,
                 out.string.strip)
  end

  def test_run_hunpos
    in_file = StringIO.new("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj \n\t\"hallo\" subst appell nøyt ub ent \n\t\"hallo\" subst appell nøyt ub fl \n<word>i</word>\n\"<i>\"\n\t\"i\" prep \n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>")
    out = StringIO.new
    disamb = TextlabOBTStat::Disambiguator.new(writer: TextlabOBTStat::VRTWriter.new(out),
                                               input_file: in_file)
    assert(disamb)
    disamb.disambiguate
    assert_equal([["hallo", "subst_prop"], ["i", "prep"], ["luken", "subst_mask_appell_ent_be"], [".", "clb_<punkt>"]],
                 disamb.hunpos_output)

    # "til sjøs" is combined by the multitagger
    in_file = StringIO.new("<word>Vi</word>\n\"<vi>\"\n\t\"vi\" pron fl pers hum nom 1 \n<word>drar</word>\n\"<drar>\"\n\t\"dra\" verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9 \n<word>til sjøs</word>\n\"<til sjøs>\"\n\t\"til sjøs\" prep prep+subst @adv \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt> \n")
    out = StringIO.new
    disamb = TextlabOBTStat::Disambiguator.new(writer: TextlabOBTStat::VRTWriter.new(out),
                                               input_file: in_file)
    assert(disamb)
    disamb.disambiguate
    assert_equal([["vi", "pron_pers_1_fl_hum_nom"], ["drar", "verb_pres"], ["til_sjøs", "prep"], [".", "clb_<punkt>"]],
                 disamb.hunpos_output)
  end
end