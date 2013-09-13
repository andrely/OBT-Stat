# encoding: utf-8

require 'test/unit'

require_relative '../obno_text'

class OBNOTextTest < Test::Unit::TestCase

  def test_is_open_sent_tag_line
    assert(TextlabOBTStat::OBNOText.is_open_sent_tag_line("<s>"))
    assert(TextlabOBTStat::OBNOText.is_open_sent_tag_line("<s id=\"1\">"))
    assert(TextlabOBTStat::OBNOText.is_open_sent_tag_line("<s id=\"1\" corresp=\"1\">"))
    assert(!TextlabOBTStat::OBNOText.is_open_sent_tag_line("ba"))
  end

  def test_is_close_sent_tag_line
    assert(TextlabOBTStat::OBNOText.is_close_sent_tag_line("</s>"))
    assert(!TextlabOBTStat::OBNOText.is_close_sent_tag_line("ba"))
  end

  def test_attributes
    attrs = TextlabOBTStat::OBNOText.attributes("<s>")
    assert_equal({}, attrs)
    attrs = TextlabOBTStat::OBNOText.attributes("ba")
    assert_nil(attrs)
    attrs = TextlabOBTStat::OBNOText.attributes("<s id=\"1\">")
    assert(attrs)
    assert_kind_of(Hash, attrs)
    assert_equal("1", attrs[:id])
  end

  def test_parse
    File.open('../../test/test.obno_parse') do |f|
      text = TextlabOBTStat::OBNOText.parse f

      assert_equal(2, text.sentences.count)
      assert_equal(20, text.sentences[0].words.count)
      assert_equal(12, text.sentences[1].words.count)

      assert_equal("vi opplever også at tolkningen av reglene avhenger av den stortingsrepresentanten som tar opp en sak , sier jørgensen .",
                   text.sentences[0].to_orig_s)
      assert_equal("men nå ser det ut til å svikte , mener jørgensen .", text.sentences[1].to_orig_s)

      assert_equal("vi opplever også at tolkningen av reglene avhenger av den stortingsrepresentanten som tar opp en sak , sier jørgensen .",
                   text.sentences[0].to_s)
      assert_equal("men nå ser det ut til å svikte , mener jørgensen .", text.sentences[1].to_s)

      assert_equal([1, 1, 1, 1, 1, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1],
                   text.sentences[0].words.collect { |w| w.tags.count})
      assert_equal([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1],
                   text.sentences[1].words.collect { |w| w.tags.count})
    end

    File.open('../../test/test.obno_parse_xml') do |f|
      text = TextlabOBTStat::OBNOText.parse(f, :xml)

      assert_equal(2, text.sentences.count)
      assert_equal(20, text.sentences[0].words.count)
      assert_equal(12, text.sentences[1].words.count)

      assert(text.sentences[0].attrs)
      assert_equal("1", text.sentences[0].attrs[:id])
      assert(text.sentences[1].attrs)
      assert_equal("2", text.sentences[1].attrs[:id])

      assert_equal("vi opplever også at tolkningen av reglene avhenger av den stortingsrepresentanten som tar opp en sak , sier jørgensen .",
                   text.sentences[0].to_orig_s)
      assert_equal("men nå ser det ut til å svikte , mener jørgensen .", text.sentences[1].to_orig_s)

      assert_equal("vi opplever også at tolkningen av reglene avhenger av den stortingsrepresentanten som tar opp en sak , sier jørgensen .",
                   text.sentences[0].to_s)
      assert_equal("men nå ser det ut til å svikte , mener jørgensen .", text.sentences[1].to_s)

      assert_equal([1, 1, 1, 1, 1, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1],
                   text.sentences[0].words.collect { |w| w.tags.count})
      assert_equal([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1],
                   text.sentences[1].words.collect { |w| w.tags.count})
    end
  end
end