# -*- coding: iso-8859-1 -*-
require 'disambiguation_context'
require 'disambiguator'
require 'evaluator'
require 'test/unit'

class DisambiguationContextTest < Test::Unit::TestCase
  def setup_context(input, eval)
    context = DisambiguationContext.new

    text = nil

    File.open(input) do |f|
      text = OBNOText.parse f
    end

    evaluator = Evaluator.new eval

    context.input = text.words
    context.hunpos = Disambiguator.run_hunpos text
    context.eval = evaluator.evaluation_data
    context.eval_active = true

    return context
  end
  
  def test_synchronize_D
    context = setup_context('test/inputD', 'test/evalD')
    
    context.advance
    context.advance

    assert_equal("i_ferd_med", (context.synchronize).collect { |i| i.normalized_string}.join('_'))

    context.advance

    assert_equal("fullstendig", context.current(:input).normalized_string)
    assert_equal("fullstendig", context.current(:eval).first)
    assert_equal("fullstendig", context.current(:hunpos).first)
  end
  
  def test_synchronize_E
    context = setup_context('test/inputE', 'test/evalE')
    context.advance
    context.advance

    assert_equal("i_hvert_fall", (context.synchronize).collect { |i| i.normalized_string}.join('_'))

    context.advance

    assert_equal("én", context.current(:input).normalized_string)
    assert_equal("én", context.current(:eval).first)
    assert_equal("én", context.current(:hunpos).first)

    16.times { |i| context.advance }
    
    assert_equal("i", context.current(:input).normalized_string)
    assert_equal("i_hop", context.current(:eval).first)
    assert_equal("i", context.current(:hunpos).first)

    assert_equal("i_hop", (context.synchronize).collect { |i| i.normalized_string}.join('_'))

    context.advance

    assert_equal("er", context.current(:input).normalized_string)
    assert_equal("er", context.current(:eval).first)
    assert_equal("er", context.current(:hunpos).first)
  end

  def test_synchronize_F
    context = setup_context('test/inputF', 'test/evalF')

    context.advance
    context.advance

    assert_equal("tir.", (context.synchronize).collect { |i| i.normalized_string}.join(''))

    context.advance

    assert_equal("--", context.current(:input).normalized_string)
    assert_equal("--", context.current(:eval).first)
    assert_equal("--", context.current(:hunpos).first)

  end
end
