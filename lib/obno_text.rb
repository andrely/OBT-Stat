# -*- coding: utf-8 -*-
# require 'lib/obno_stubs'

class OBNOText
  attr_accessor :test

  @word_regex = Regexp.compile('^\s*\"<(.*)>\"\s*$')
  @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
  @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
  @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

  # Parses the OB text in filedata and populates the Text instance argument
  # with the result.
  # file - A File instance to read input from
  # returns true
  def self.parse(file)
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
        if isPunctuation(word.string) then
          sentence.length = index
          sentence.text_index = sent_count
          text.sentences << sentence
          sentence = Sentence.new
          index = 0
          sent_count += 1
        end
      
      # if we got a tag, parse it and populate a Tag instance that is pushed onto
      # the tag list of the current word
      elsif isTagLine(line) then
        tag = Tag.new
        lemma, string, correct, capitalized = getTag(line)
        tag.lemma = lemma.strip
        tag.string = string.strip
        tag.correct = correct
        tag.capitalized = capitalized
        tag.index = tag_index
        tag_index += 1
        word.tags << tag
        tag.input_string = line
        
      # line with unknown data
      else
        preamble << line
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
      return [m[1], m[2], !m[5].nil?, !m[3].nil?]
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
