# -*- coding: utf-8 -*-
require 'obno_stubs'

class OBNOText
  attr_accessor :test

  @word_regex = Regexp.compile('\"<(.*)>\"')
  @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
  @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
  @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

  def initialize()
  end
  
  # Parses the OB text in filedata and populates the Text instance argument
  # with the result.
  # textinst - A Text instance where the parsed data is stored
  # filedata - The input data lines as a single string
  # returns true
  def self.parse(textinst, filedata)
    word = nil
    orig_word = nil
    sentence = Sentence.new
    sent_count = 0
    index = 0
    tag_index = 0

    filedata.each_line do |line|
      # if there is an original word form, store it and put in the Word instance
      # when we encounter the OB word line
      if isOrigWordLine(line)
        # there shouldn't be two original word lines without the corresponding OB
        # word data. Error if this happens
        if not orig_word.nil?
          raise RuntimeError
        end
        
        orig_word = GetOrigWordLine(line)
      end
      
      # if we got a new OB word, create a new word, populate it with the parsed
      # data and push it on the sentence word list
      if isWordLine(line) then
        word = Word.new
        word.string = getWord(line).strip

        # store the original word string if there is one
        word.orig_string = orig_word
        # erase the stored original word string to avoid it being inserted later
        orig_word = nil
        
        word.sentence_index = index
        word.tag_count = tag_index
        sentence.words << word
        index += 1
        tag_index = 0
        
        # if there is a sentence boundary, push the sentence on the texts sentence
        # list and create a new sentence instance.
        if isPunctuation(word.string) then
          sentence.length = index
          sentence.text_index = sent_count
          textinst.sentences << sentence
          sentence = Sentence.new
          index = 0
          sent_count += 1
        end
      end
      
      # if we got a tag, parse it and populate a Tag instance that is pushed onto
      # the tag list of the current word
      if isTagLine(line) then
        tag = Tag.new
        lemma, string, correct = getTag(line)
        tag.lemma = lemma.strip
        tag.string = string.strip
        tag.correct = correct
        tag.index = tag_index
        tag_index += 1
        word.tags << tag
      end
    end
    
    # store the last sentence when we're done
    if index > 0 then
      sentence.length = index
      sentence.text_index = sent_count
      textinst.sentences << sentence
      sent_count += 1
    end
    textinst.sentence_count = sent_count
    textinst.save!
  end

  def self.textString(text)
    ret_str = []
    # sentences = text.sentences.sort_by {|s| s.text_index }
    sentences = Sentence.find(:all, :conditions => ["tagged_text_id = ?", text.id], :order => "text_index", :include => [:words])
    sentences.each do |s|
      # words = s.words.sort_by {|w| w.sentence_index }
      words = Word.find(:all, :conditions => ["sentence_id = ?", s.id], :order => "sentence_index", :include => [:tags])
      words.each do |w|
        ret_str << '"<' + w.string + '>"'
        tags = w.tags.sort_by {|t| t.index }
        tags.each do |t|
          ret_str << "\t" + '"' + t.lemma + '" ' + t.string + (t.correct ? ' <Correct!>' : '')
        end
      end
    end

    ret_str.join("\n")
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
      return [m[1], m[2], !m[3].nil?]
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
