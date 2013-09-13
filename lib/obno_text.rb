# -*- coding: utf-8 -*-
require_relative 'obno_stubs'

module TextlabOBTStat

  class OBNOTextIterator
    attr_reader :file, :postamble

    @peeked_word_record = nil
    @peeked_orig_word_record = nil
    @peeked_preamble = nil
    @postamble

    def initialize(file, use_static_punctuation = false)
      @file = file

      @word_regex = Regexp.compile('\"<(.*)>\"')
      @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
      @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
      @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

      @use_static_punctuation = use_static_punctuation
    end

    def each_sentence
      while sentence = get_next_sentence(file)
        yield sentence
      end
    end

    def get_next_sentence(f)
      sentence = Sentence.new

      begin
        while word = get_next_word(f)
          sentence.words << word

          break if word.is_punctuation? and @use_static_punctuation
          break if word.end_of_sentence_p and not @use_static_punctuation
        end
      rescue EOFError
        if @peeked_word_record or @peeked_orig_word_record
          raise RuntimeError
        else
          @postamble = @peeked_preamble
        end
      end

      return nil if sentence.words.empty?

      sentence
    end

    def get_next_word(f)
      word = Word.new
      word.string, word.orig_string, word.preamble = get_word_header(f)

      word.tags = get_word_tags(f, word)

      raise RuntimeError if word.tags.empty?

      word
    end

    def get_word_tags(f, word)
      tags = []

      while line = f.readline
        if is_tag_line(line)
          tag = Tag.new
          tag.lemma, tag.string, tag.correct, tag.capitalized, word.end_of_sentence_p = get_tag(line)
          tags << tag
        else
          peek line
          break
        end
      end

      raise RuntimeError if tags.empty?

      tags
    end

    def get_word_header(f)
      if @peeked_word_record
        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      elsif @peeked_orig_word_record
        @peeked_word_record = get_word(f.readline)
        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      else
        while line = f.readline
          peek line

          break if @peeked_word_record
        end

        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      end

      unpeek

      header
    end

    def peek(line)
      if is_word_line(line)
        @peeked_word_record = get_word(line)
      elsif is_orig_word_line(line)
        @peeked_orig_word_record = get_orig_word(line)
      else
        if @peeked_preamble
          @peeked_preamble << line.strip
        else
          @peeked_preamble = [line.strip]
        end
      end
    end

    def unpeek()
      @peeked_word_record = nil
      @peeked_orig_word_record = nil
      @peeked_preamble = nil
    end

    def is_word_line(line)
      line.match(@word_regex)
    end

    def get_word(line)
      if (m = line.match(@word_regex)) then
        return m[1]
      end

      nil
    end

    def is_tag_line(line)
      line.match(@tag_regex)
    end

    def self.get_tag(line)
      if (m = line.match(@tag_regex))
        lemma = m[1]
        tag = m[2]
        correct = !m[5].nil?
        capitalized = !m[3].nil?
        end_of_sentence = nil

        # detect end of sentence marker and remove it
        if tag.match("\s+<<<\s+")
          tag = tag.gsub(/\s+<<<\s+/, " ")
          end_of_sentence = true
        end

        return [lemma, tag, correct, capitalized, end_of_sentence]
      end

      return nil
    end

    # Checks if the passed line contains an original word string.
    # line - an OB output line
    # returns true if the line matches the original word line format, nil if not
    def is_orig_word_line(line)
      line.match(@orig_word_regex)
    end

    # Extracts the original word string if thtis line matches the original word line format, ie.
    # the word string in an XML word tag.
    # line - an OB output line
    # returns the original word string if the line matches, nil otherwise
    def get_orig_word(line)
      if m = line.match(@orig_word_regex)
        return m[1]
      end

      nil
    end
  end

  class OBNOText
    @word_regex = Regexp.compile('^\s*\"<(.*)>\"\s*$')
    @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
    @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
    @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

    # XML tag containing sentences in TEI documents.
    SENT_SEG_TAG = 's'
    OPEN_SENT_TAG_REGEX = Regexp.compile("^\\w*<#{SENT_SEG_TAG}(.*)?>")
    CLOSE_SENT_TAG_REGEX = Regexp.compile("^\\w*</#{SENT_SEG_TAG}>")

    # Parses the OB text in filedata and populates the Text instance argument
    # with the result.
    #
    # @param [IO, StringIO] file
    # @param [Symbol] sent_seg How to segment sentences (:mtag, :static, :xml)
    # @return [Text] Parsed text input.
    def self.parse(file, sent_seg=:static)
      text = Text.new

      word = nil
      orig_word = nil
      sentence = Sentence.new
      sent_count = 0
      index = 0
      tag_index = 0
      preamble = []

      file.each_line do |line|
        # if there is an original word form, store it and put in the Word instance
        # when we encounter the OB word line
        if is_orig_word_line(line)
          # there shouldn't be two original word lines without the corresponding OB
          # word data. Error if this happens
          unless orig_word.nil?
            raise RuntimeError
          end

          orig_word = get_orig_word_line(line)
          preamble << line

          # if we got a new OB word, create a new word, populate it with the parsed
          # data and push it on the sentence word list
        elsif is_word_line(line)
          word = Word.new
          word.string = get_word(line).strip

          # store the original word string if there is one
          word.orig_string = orig_word
          # erase the stored original word string to avoid it being inserted later
          orig_word = nil

          word.preamble = preamble
          preamble = []

          word.sentence_index = index
          word.tag_count = tag_index
          sentence.words << word
          index += 1
          tag_index = 0

          word.input_string = line

          # if there is a sentence boundary, push the sentence on the texts sentence
          # list and create a new sentence instance.
          if is_punctuation(word.string) and sent_seg == :static
            word.end_of_sentence_p = true
          end

          # if we got a tag, parse it and populate a Tag instance that is pushed onto
          # the tag list of the current word
        elsif is_tag_line(line)
          tag = Tag.new
          lemma, string, correct, capitalized, end_of_sentence = get_tag(line)
          tag.lemma = lemma.strip
          tag.string = string.strip
          tag.correct = correct
          tag.capitalized = capitalized
          tag.index = tag_index
          tag_index += 1
          word.tags << tag
          tag.input_string = line

          if end_of_sentence and sent_seg == :mtag
            word.end_of_sentence_p = true
          end
        elsif sent_seg == :xml and is_open_sent_tag_line(line)
          # @todo around tags other input should be added to preamble
          attrs = attributes(line)
          sentence.attrs = attrs
        elsif sent_seg == :xml and is_close_sent_tag_line(line)
          word.end_of_sentence_p = true
        else
          # line with unknown data
          preamble << line
        end

        if word and word.end_of_sentence_p
          # @todo hacky
          # if index is not reset we haven't started a new sentence
          unless index == 0
            sentence.length = index
            sentence.text_index = sent_count
            text.sentences << sentence
            sentence = Sentence.new
            index = 0
            sent_count += 1
          end
        end
      end

      # store the last sentence when we're done
      if index > 0
        sentence.length = index
        sentence.text_index = sent_count
        text.sentences << sentence
        sent_count += 1
      end

      text.postamble = preamble
      text.sentence_count = sent_count

      return text
    end

    def self.is_word_line(line)
      line.match(@word_regex)
    end

    def self.get_word(line)
      if (m = line.match(@word_regex)) then
        return m[1]
      end

      return nil
    end

    def self.is_tag_line(line)
      line.match(@tag_regex)
    end

    # @param [String] line
    # @return [TrueClass, FalseClass]
    def self.is_open_sent_tag_line(line)
      not line.match(OPEN_SENT_TAG_REGEX).nil?
    end

    # @param [String] line
    # @return [TrueClass, FalseClass] true if line contains closing sentence segmention tag.
    def self.is_close_sent_tag_line(line)
      not line.match(CLOSE_SENT_TAG_REGEX).nil?
    end

    # @param [String] tag_line String containing tag.
    # @return [NilClass, Hash] Hash containing the attributes if a tag is present in the string, nil otherwise.
    def self.attributes(tag_line)
      m = tag_line.match(OPEN_SENT_TAG_REGEX)
      return nil if m.nil? or m.captures.empty?
      attr = {}

      attr_str = m.captures.first
      attr_str.split.each do |str|
        id, val = str.split('=')
        attr[id.to_sym] = TextlabOBTStat::remove_quotes(val.strip)
      end

      attr
    end

    def self.get_tag(line)
      if (m = line.match(@tag_regex))
        lemma = m[1]
        tag = m[2]
        correct = !m[5].nil?
        capitalized = !m[3].nil?
        end_of_sentence = nil

        # detect end of sentence marker and remove it
        if tag.match("\s+<<<\s+")
          tag = tag.gsub(/\s+<<<\s+/, " ")
          end_of_sentence = true
        end

        return [lemma, tag, correct, capitalized, end_of_sentence]
      end

      return nil
    end

    def self.is_punctuation(str)
      return str.match(@punctuation_regex)
    end

    # Checks if the passed line contains an original word string.
    # line - an OB output line
    # returns true if the line matches the original word line format, nil if not
    def self.is_orig_word_line(line)
      line.match(@orig_word_regex)
    end

    # Extracts the original word string if thtis line matches the original word line format, ie.
    # the word string in an XML word tag.
    # line - an OB output line
    # returns the original word string if the line matches, nil otherwise
    def self.get_orig_word_line(line)
      if m = line.match(@orig_word_regex)
        return m[1]
      end

      return nil
    end
  end
end
