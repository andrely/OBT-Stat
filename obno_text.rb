# -*- coding: utf-8 -*-
class OBNOText
  attr_accessor :test

  @word_regex = Regexp.compile('\"<(.*)>\"')
  @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
  @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?

  def initialize()
  end

  def self.parse(textinst, filedata)
    word = nil
    sentence = Sentence.new
    sent_count = 0
    index = 0
    tag_index = 0
    # file = File.new(file, 'r')
    # while (line = file.gets)
    filedata.each_line do |line|
      if isWordLine(line) then
        word = Word.new
        word.string = getWord(line).strip
        word.sentence_index = index
        word.tag_count = tag_index
        sentence.words << word
        index += 1
        tag_index = 0

        if isPunctuation(word.string) then
          sentence.length = index
          sentence.text_index = sent_count
          textinst.sentences << sentence
          sentence = Sentence.new
          index = 0
          sent_count += 1
        end
      end

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
end
