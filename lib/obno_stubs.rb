# -*- coding: utf-8 -*-
# stub ActiveRecord classes from tag-annotator
class Text
  attr_accessor :sentence_count, :sentences, :postamble

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
  attr_accessor :string, :orig_string, :sentence_index, :tag_count, :tags, :input_string, :preamble, :end_of_sentence_p
  
  @@punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
  
  def initialize
    @tags = []
    @preamble = []
    @end_of_sentence_p = nil
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
  
  # returns the appropriate string for output from the tagger
  # that is the original string if available otherwise the OB
  # word form string
  def output_string
    return (@orig_string or @string)
  end

  def tag_by_string(str)
    @tags.each do |t|
      # return t if str == t.clean_out_tag
      return t if t.equal(str)
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
    # @tags.find { |t| t.clean_out_tag == tag }
    @tags.find { |t| t.equal(tag) }
  end

  def word_count
    string.split(/\s/).length
  end

  def get_correct_tags
    return @tags.find_all { |t| t.correct }
  end

  def get_correct_tag
    correct_tags = get_correct_tags
    raise RuntimeError if correct_tags.count > 1

    return correct_tags.first
  end

  def get_selected_tag
    raise RuntimeError if ambigious?

    return @tags.first
  end

  def get_selected_tag
    selected = @tags.find_all { |t| t.selected }

    raise RuntimeError if selected.length > 1
    
    # nil implicitly returned if no tag is selected
    return selected.first
  end

  def correct_count
    return get_correct_tags.length
  end
  
  # this must be expanded if sentence segmentation is made more complex
  def capitalized?
    if @sentence_index == 0
      return true
    elsif get_correct_tags.count > 0
      return get_correct_tags.first.capitalized
    else
      return @tags.all? { |t| t.capitalized }
    end
  end

  def is_punctuation?
    return @string.match(@@punctuation_regex)
  end
  
  def remove_duplicate_clean_tags!
    seen = []

    @tags.each do |tag|
      if seen.member?([tag.clean_out_tag, tag.lemma])
        @tags.delete(tag)
      else
        seen << [tag.clean_out_tag, tag.lemma]
      end
    end

    return @tags
  end

  def end_of_sentence?
    return @end_of_sentence_p
  end
end

class Tag
  attr_accessor :lemma, :string, :correct, :selected, :capitalized, :index, :input_string

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
    
    # we treat clb marked punctuation the same as unmarked
    if tag.match(/^clb /)
      tag = tag.gsub(/^clb (.*)$/, '\1')
    end
    
    return tag.gsub(@@clean_tag_regex, '').strip.gsub(/\s+/, '_')
  end

  def initialize
    @correct = nil
  end

  def equal(tag_str)
    # assume we're passed a clean out style tag
    elts = tag_str.split('_')
    tag_elts = clean_out_tag.split('_')

    return false if elts.count != tag_elts.count
    
    tag_elts.each do |e|
      return nil if not elts.include? e
    end

    $tracer.message "EQUAL: #{clean_out_tag} - #{tag_str}"
    
    return true
    # return clean_out_tag == tag_str
  end
end
