# encoding: utf-8

require 'test/unit'

require 'stringio'

require_relative '../disambiguation_context'
require_relative '../obno_text'

class DisambiguationContextTest < Test::Unit::TestCase

  def test_disambiguation_context
    obt_input = StringIO.new("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj \n\t\"hallo\" subst appell nøyt ub ent \n\t\"hallo\" subst appell nøyt ub fl \n<word>i</word>\n\"<i>\"\n\t\"i\" prep \n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>")
    obt_text = TextlabOBTStat::OBNOText.parse(obt_input)
    assert(obt_text)
    hunpos_input = [["hallo", "subst_prop"], ["i", "prep"], ["luken", "subst_mask_appell_ent_be"], [".", "clb_<punkt>"]]

    context = TextlabOBTStat::DisambiguationContext.new(obt_text.words, hunpos_input)
    assert(context)
    assert_equal("hallo", context.current[0].string)
    assert_equal("hallo", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal("i", context.current[0].string)
    assert_equal("i", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal("luken", context.current[0].string)
    assert_equal("luken", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal(".", context.current[0].string)
    assert_equal(".", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert(context.at_end?)

    obt_input = StringIO.new("<word>Vi</word>\n\"<vi>\"\n\t\"vi\" pron fl pers hum nom 1 \n<word>drar</word>\n\"<drar>\"\n\t\"dra\" verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9 \n<word>til sjøs</word>\n\"<til sjøs>\"\n\t\"til sjøs\" prep prep+subst @adv \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt> \n")
    obt_text = TextlabOBTStat::OBNOText.parse(obt_input)
    assert(obt_text)
    hunpos_input = [["vi", "pron_pers_1_fl_hum_nom"], ["drar", "verb_pres"], ["til_sjøs", "prep"], [".", "clb_<punkt>"]]

    context = TextlabOBTStat::DisambiguationContext.new(obt_text.words, hunpos_input)
    assert(context)
    assert_equal("vi", context.current[0].string)
    assert_equal("vi", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal("drar", context.current[0].string)
    assert_equal("drar", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal("til sjøs", context.current[0].string)
    assert_equal("til_sjøs", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert_equal(".", context.current[0].string)
    assert_equal(".", context.current[1][0])
    assert_false(context.at_end?)
    context.advance
    assert(context.at_end?)
  end
end