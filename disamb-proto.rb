#!/local/bin/ruby

require "open3"
require "obno_text"

$hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag /hf/foni/home/andrely/ob-disambiguation-prototype/disamb.hunpos.model"

# stub ActiveRecor classes from tag-annotator
class Text
  attr_accessor :sentence_count, :sentences

  def initialize
    @sentences = []
  end

  # stub of ActiveRecord method
  def save!
    true
  end
end

class Sentence
  attr_accessor :words, :length, :text_index

  def initialize
    @words = []
  end
end

class Word
  attr_accessor :string, :sentence_index, :tag_count, :tags

  def initialize
    @tags = []
  end
end

class Tag
  attr_accessor :lemma, :string, :correct, :index

  @@clean_tag_regex = Regexp.compile('((i|pa|tr|pr|r|rl|a|d|n)\d+(\/til)?)')


  def clean_out_tag
    self.string.gsub(@@clean_tag_regex, '').strip.gsub(/\s+/, '_')
  end

  def initialize
    @correct = nil
  end
end

if __FILE__ == $0
  # get input
  text = Text.new
  OBNOText.parse text, ARGF.read
  
  # run hunpos
  i, o, e = Open3.popen3 $hunpos_command
 
  text.sentences.each do |s|
    s.words.each do |w|
      i.puts w.string
    end
  end

  i.close

  # o.each_line do |line|
  #   $stderr.puts line
  # end

  # output and merge disambigious words
  text.sentences.each do |s|
    s.words.each do |w|
      # not ambigious
      if w.tags.count == 1
        puts w.string + "\t" + w.tags.first.clean_out_tag
        o.gets
      # ambigious
      else
        # get and parse line from hunpos process
        hun_line = o.gets.strip
        hun_word, hun_tag = hun_line.split(/\s/)

        # fetch tags
        tags = w.tags.collect {|t| t.clean_out_tag}

        # sanity check on input position
        raise RuntimeError if hun_word != w.string

        # us hunpos tag if found, just take the first tag otherwise
        if tags.include? hun_tag
          $stderr.puts "ambiguity hunpos tag #{hun_tag} chosen"

          puts w.string + "\t" + hun_tag
        else
          $stderr.puts "ambiguity ob tag #{w.tags.first.clean_out_tag} chosen"

          puts w.string + "\t" + w.tags.first.clean_out_tag
        end
      end
    end
  end
end
