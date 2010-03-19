# -*- coding: utf-8 -*-
# stub ActiveRecord classes from tag-annotator
class Text
  attr_accessor :sentence_count, :sentences

  def initialize
    @sentences = []
  end

  # returns a flattened array of all words in the
  # text instance
  def words
    sentences = @sentences.collect do |s|
      s.words
    end

    return sentences.flatten
  end
end

class Sentence
  attr_accessor :words, :length, :text_index

  def initialize
    @words = []
  end

  def to_s
    @words.collect {|w| w.normalized_string }.join(' ')
  end

  def to_orig_s
    @words.collect { |w| w.orig_string }.join(' ')
  end
end

class Word
  attr_accessor :string, :orig_string, :sentence_index, :tag_count, :tags

  def initialize
    @tags = []
  end

  def normalized_string
    # remove space in front of percent sign
    if @string.match(/^\d+\s+\%$/)
      return @string.gsub(/^(\d+)\s+(\%)$/, '\1\2')
    end

    # normalize fancy qoutes to ascii ones
    string = @string.gsub(/[«»]/, '"')
    
    string = string.gsub(/\$([\.\:\|\?\!\,\(\)\-\"\;])/, '\1')
    return string.gsub(/\s/, '_')
  end

  def tag_by_string(str)
    @tags.each do |t|
      return t if str == t.clean_out_tag
    end

    return nil
  end

  def get_ambiguities
    return @tags.length
  end

  def ambigious?
    return get_ambiguities > 1
  end

  def match_clean_out_tag(tag)
    @tags.find { |t| t.clean_out_tag == tag }
  end

  def word_count
    string.split(/\s/).length
  end

  def get_correct_tags
    return @tags.find_all { |t| t.correct }
  end

  def correct_count
    return get_correct_tags.length
  end
end

class Tag
  attr_accessor :lemma, :string, :correct, :index

  @@clean_tag_regex = Regexp.compile('((i|pa|tr|pr|r|rl|a|d|n)\d+(\/til)?)')


  def clean_out_tag
    tag = @string
    
    # remove unnecessary info from the tag field for "joined words". These words
    # uniquely have a @ in their tag, with the tag being the token in front of this.
    #
    # ie. "prep+subst prep @adv" is turned into "prep" from the middle field
    if tag.match('@')
      tag = tag.gsub(/^[\w\+]+\s(\w+)\s@.+$/, '\1')
    end
    
    return tag.gsub(@@clean_tag_regex, '').strip.gsub(/\s+/, '_')
  end

  def initialize
    @correct = nil
  end
end
