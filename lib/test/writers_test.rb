require 'test/unit'

require_relative '../writers'
require_relative '../../lib/obno_stubs'

class WritersTest < Test::Unit::TestCase
  def test_input_writer
    out = StringIO.new
    writer = InputWriter.new(out)
    assert(writer)
    word = Word.new
    word.preamble = ['ba', 'foo']
    word.input_string = 'word'
    tag = Tag.new
    tag.input_string = 'tag'
    tag.selected = true
    word.tags = [tag]

    writer.write(word)
    writer.write_sentence_delimiter(word)
    assert_equal("ba\nfoo\nword\ntag\n", out.string)
  end

  def test_vrt_writer
    out = StringIO.new
    writer = VRTWriter.new(out)
    assert(writer)
    word = Word.new
    word.preamble = ['ba', 'foo']
    word.string = 'word'
    tag = Tag.new
    tag.string = 'tag'
    tag.lemma = 'lemma'
    tag.selected = true
    word.tags = [tag]

    writer.write(word)
    writer.write_sentence_delimiter(word)
    assert_equal("word\tlemma\ttag\n\n", out.string)
  end

  def test_mark_writer
    out = StringIO.new
    writer = MarkWriter.new(out)
    assert(writer)
    word = Word.new
    word.preamble = ['ba', 'foo']
    word.input_string = 'word'
    tag = Tag.new
    tag.input_string = 'tag'
    tag.selected = true
    word.tags = [tag]

    writer.write(word)
    writer.write_sentence_delimiter(word)
    assert_equal("ba\nfoo\nword\ntag <SELECTED> <ERROR>\n", out.string)
  end
end