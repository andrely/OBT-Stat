# -*- coding: utf-8 -*-
require 'obno_text'
require 'test/unit'

class OBNOTextTest < Test::Unit::TestCase
  def test_parse
    File.open('test/test.obno_parse') do |f|
      text = OBNOText.parse f

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
  end
end
