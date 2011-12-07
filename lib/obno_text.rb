# -*- coding: utf-8 -*-
# require 'lib/obno_stubs'

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
    File.open(@file) do |f|
      # @peeked_word_record, @peeked_orig_word_record, @peeked_preamble = get_word_header(f)
      
      while sentence = get_next_sentence(f)
        yield sentence
      end
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

    return sentence
  end

  def get_next_word(f)
    word = Word.new
    word.string, word.orig_string, word.preamble = get_word_header(f)

    word.tags = get_word_tags(f, word)

    raise RuntimeError if word.tags.empty?

    return word
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

    return tags
  end

  def get_word_header(f)
    header = nil
    
    if @peeked_word_record
      header = [@peeked_word_record, @peeked_orig_word_record, @peeled_preamble]
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

    return header
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

    return nil
  end

  def is_tag_line(line)
    line.match(@tag_regex)
  end

    def self.getTag(line)
    if (m = line.match(@tag_regex)) then
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
    
    return nil
  end
end

class OBNOText
  @word_regex = Regexp.compile('^\s*\"<(.*)>\"\s*$')
  @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
  @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
  @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

  # Parses the OB text in filedata and populates the Text instance argument
  # with the result.
  # file - A File instance to read input from
  # returns true
  def self.parse(file, use_static_punctuation = false)
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
      if isOrigWordLine(line)
        # there shouldn't be two original word lines without the corresponding OB
        # word data. Error if this happens
        if not orig_word.nil?
          raise RuntimeError
        end
        
        orig_word = GetOrigWordLine(line)
        preamble << line
      
      # if we got a new OB word, create a new word, populate it with the parsed
      # data and push it on the sentence word list
      elsif isWordLine(line) then
        word = Word.new
        word.string = getWord(line).strip

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
        if isPunctuation(word.string) and use_static_punctuation then
          word.end_of_sentence_p = true
         end
      
      # if we got a tag, parse it and populate a Tag instance that is pushed onto
      # the tag list of the current word
      elsif isTagLine(line) then
        tag = Tag.new
        lemma, string, correct, capitalized, end_of_sentence = getTag(line)
        tag.lemma = lemma.strip
        tag.string = string.strip
        tag.correct = correct
        tag.capitalized = capitalized
        tag.index = tag_index
        tag_index += 1
        word.tags << tag
        tag.input_string = line

        if end_of_sentence and not use_static_punctuation then
          word.end_of_sentence_p = true
        end
        
      # line with unknown data
      else
        preamble << line
      end

      if word and word.end_of_sentence_p then
        sentence.length = index
        sentence.text_index = sent_count
        text.sentences << sentence
        sentence = Sentence.new
        index = 0
        sent_count += 1
      end
    end
    
    # store the last sentence when we're done
    if index > 0 then
      sentence.length = index
      sentence.text_index = sent_count
      text.sentences << sentence
      sent_count += 1
    end

    text.postamble = preamble
    text.sentence_count = sent_count

    return text
  end

  def self.isWordLine(line)
    line.match(@word_regex)
  end

  def self.getWord(line)
    if (m = line.match(@word_regex)) then
      return m[1]
    end

    return nil
  end

  def self.isTagLine(line)
    line.match(@tag_regex)
  end

  def self.getTag(line)
    if (m = line.match(@tag_regex)) then
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

  def self.isPunctuation(str)
    return str.match(@punctuation_regex)
  end
  
  # Checks if the passed line contains an original word string.
  # line - an OB output line
  # returns true if the line matches the original word line format, nil if not
  def self.isOrigWordLine(line)
    line.match(@orig_word_regex)
  end

  # Extracts the original word string if thtis line matches the original word line format, ie.
  # the word string in an XML word tag.
  # line - an OB output line
  # returns the original word string if the line matches, nil otherwise
  def self.GetOrigWordLine(line)
    if m = line.match(@orig_word_regex)
      return m[1]
    end
    
    return nil
  end
end
