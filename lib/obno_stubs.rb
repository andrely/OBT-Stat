# -*- coding: utf-8 -*-

module TextlabOBTStat

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

      sentences.flatten
    end
  end

  class Sentence
    attr_accessor :words, :length, :text_index, :attrs

    def initialize
      @words = []
      # attributes on the sentence delimiter tag if any
      # empty hash here means there was a tag with no attributes
      @attrs = nil
    end

    def to_s
      @words.collect {|w| w.normalized_string }.join(' ')
    end

    def to_orig_s
      @words.collect { |w| w.orig_string }.join(' ')
    end
  end

  class Word
    attr_accessor :string, :orig_string, :sentence_index, :tag_count, :tags, :input_string, :preamble,
                  :end_of_sentence_p

    PUNCTUATION_REGEX = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?

    def initialize
      @string = nil
      @orig_string = nil
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
      string.gsub(/\s/, '_')
    end

    # returns the appropriate string for output from the tagger
    # that is the original string if available otherwise the OB
    # word form string
    def output_string
      (@orig_string or @string)
    end

    def tag_by_string(str)
      @tags.each do |t|
        # return t if str == t.clean_out_tag
        return t if t.equal(str)
      end

      nil
    end

    def get_ambiguities
      @tags.length
    end

    def ambigious?
      get_ambiguities > 1
    end

    def match_clean_out_tag(tag)
      # @tags.find { |t| t.clean_out_tag == tag }
      @tags.find { |t| t.equal(tag) }
    end

    def word_count
      string.split(/\s/).length
    end

    def get_correct_tags
      @tags.find_all { |t| t.correct }
    end

    def get_correct_tag
      correct_tags = get_correct_tags
      raise RuntimeError if correct_tags.count > 1

      correct_tags.first
    end

    def get_selected_tag
      selected = @tags.find_all { |t| t.selected }

      raise RuntimeError if selected.length > 1

      # nil implicitly returned if no tag is selected
      selected.first
    end

    def correct_count
      get_correct_tags.length
    end

    # this must be expanded if sentence segmentation is made more complex
    def capitalized?
      if @sentence_index == 0
        true
      elsif get_correct_tags.count > 0
        get_correct_tags.first.capitalized
      else
        @tags.all? { |t| t.capitalized }
      end
    end

    def is_punctuation?
      @string.match(PUNCTUATION_REGEX)
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

      @tags
    end

    def end_of_sentence?
      @end_of_sentence_p
    end
  end

  class Tag
    attr_accessor :lemma, :string, :correct, :selected, :capitalized, :index, :input_string

    CLEAN_TAG_REGEX = Regexp.compile('((i|pa|tr|pr|r|rl|a|d|n)\d+(\/til)?)')

    def initialize
      @string = nil
      @correct = nil
    end

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

      tag.gsub(CLEAN_TAG_REGEX, '').strip.gsub(/\s+/, '_')
    end

    def equal(tag_str)
      # assume we're passed a clean out style tag
      elts = tag_str.split('_')
      tag_elts = clean_out_tag.split('_')

      return false if elts.count != tag_elts.count

      tag_elts.each do |e|
        return nil if not elts.include? e
      end

      true
    end
  end
end
