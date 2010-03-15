# -*- coding: utf-8 -*-
require 'lemma_model'
require 'obno_stubs'
require 'obno_text'
require 'test/unit'
require 'tempfile'

class LemmaModelTest < Test::Unit::TestCase

  # creates a model from a cor file and checks the top lemma of
  # somw words
  def test_create_lemma_model
    lm = LemmaModel.new
    lm.create_lemma_model 'test/test.lemma_train'

    assert_equal("fra", lm.top_lemma("fra"))
    assert_equal("være", lm.top_lemma("er"))
    assert_equal("mens", lm.top_lemma("mens"))
    assert_equal("betydning", lm.top_lemma("betydning"))
    assert_equal("forsvarsindustri", lm.top_lemma("forsvarsindustrien"))
  end
  
  # reads a lemma model file and checks the top lemma of all the entries
  def test_read_lemma_model
    lm = LemmaModel.new
    lm.read_lemma_model 'test/test.lemma_model'

    assert_equal("gullstoff", lm.top_lemma("gullstoffer"))
    assert_equal("lett", lm.top_lemma("lette"))
    assert_equal("1", lm.top_lemma("1"))
    assert_equal("dommer", lm.top_lemma("dommer"))
    assert_equal("fart", lm.top_lemma("fart"))
    assert_equal("i kraft av", lm.top_lemma("i kraft av"))
  end

  def test_write_lemma_modek
    lm = LemmaModel.new
    lm.create_lemma_model 'test/test.lemma_train'

    file = Tempfile.new('test.lemma.model').path

    lm.write_lemma_model file

    lm2 = LemmaModel.new
    lm2.read_lemma_model file

    assert_equal(lm2.model, lm.model)

    File.delete file
  end
end
