require 'test/unit'

require_relative '../writers'
require_relative '../../lib/obno_stubs'

class WritersTest < Test::Unit::TestCase
  def test_input_writer
    out = StringIO.new
    writer = TextlabOBTStat::InputWriter.new(file: out)
    assert(writer)
    word = TextlabOBTStat::Word.new
    word.preamble = ['ba', 'foo']
    word.input_string = 'word'
    tag = TextlabOBTStat::Tag.new
    tag.input_string = 'tag'
    tag.selected = true
    word.tags = [tag]

    sent = TextlabOBTStat::Sentence.new
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("ba\nfoo\nword\ntag\n", out.string)

    # Input writer preserves any embedded lines including XML
    out = StringIO.new
    writer = TextlabOBTStat::InputWriter.new(file: out)
    assert(writer)
    sent.attrs = { id: "1" }
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("<s id=\"1\">\nba\nfoo\nword\ntag\n</s>\n", out.string)

    # Output should be the same if XML markup is explicitly reserved
    out = StringIO.new
    writer = TextlabOBTStat::InputWriter.new(file: out, xml: true)
    assert(writer)
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("<s id=\"1\">\nba\nfoo\nword\ntag\n</s>\n", out.string)
  end

  def test_vrt_writer
    out = StringIO.new
    writer = TextlabOBTStat::VRTWriter.new(file: out)
    assert(writer)
    word = TextlabOBTStat::Word.new
    word.preamble = ['ba', 'foo']
    word.string = 'word'
    tag = TextlabOBTStat::Tag.new
    tag.string = 'tag'
    tag.lemma = 'lemma'
    tag.selected = true
    word.tags = [tag]
    sent = TextlabOBTStat::Sentence.new

    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("word\tlemma\ttag\n\n", out.string)

    # XML not echoed unless requested
    sent.attrs = { id: "1" }
    out = StringIO.new
    writer = TextlabOBTStat::VRTWriter.new(file: out)
    assert(writer)
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("word\tlemma\ttag\n\n", out.string)

    out = StringIO.new
    writer = TextlabOBTStat::VRTWriter.new(file: out, xml: true)
    assert(writer)
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("<s id=\"1\">\nword\tlemma\ttag\n</s>\n", out.string)
  end

  def test_mark_writer
    out = StringIO.new
    writer = TextlabOBTStat::MarkWriter.new(file: out)
    assert(writer)
    word = TextlabOBTStat::Word.new
    word.preamble = ['ba', 'foo']
    word.input_string = 'word'
    tag = TextlabOBTStat::Tag.new
    tag.input_string = 'tag'
    tag.selected = true
    word.tags = [tag]
    sent = TextlabOBTStat::Sentence.new

    writer.write(word)
    writer.write_sentence_header(sent)
    writer.write_sentence_footer(sent)
    assert_equal("ba\nfoo\nword\ntag <SELECTED> <ERROR>\n", out.string)

    sent.attrs = { id: "1" }
    out = StringIO.new
    writer = TextlabOBTStat::MarkWriter.new(file: out)
    assert(writer)
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("<s id=\"1\">\nba\nfoo\nword\ntag <SELECTED> <ERROR>\n</s>\n", out.string)

    out = StringIO.new
    writer = TextlabOBTStat::MarkWriter.new(file: out, xml: true)
    assert(writer)
    writer.write_sentence_header(sent)
    writer.write(word)
    writer.write_sentence_footer(sent)
    assert_equal("<s id=\"1\">\nba\nfoo\nword\ntag <SELECTED> <ERROR>\n</s>\n", out.string)
  end
end