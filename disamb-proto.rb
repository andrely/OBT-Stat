#!/local/bin/ruby

require "open3"
require "getoptlong"

require "obno_text"
require "disambiguator"
require "evaluator"

# $hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag /hf/foni/home/andrely/ob-disambiguation-prototype/disamb.hunpos.model"
$hunpos_command = "./hunpos-1.0-macosx/hunpos-tag ./bm.hunpos.model"

$eval_file = 'test/evalB'

# stub ActiveRecord classes from tag-annotator
class Text
  attr_accessor :sentence_count, :sentences

  def initialize
    @sentences = []
  end

  # stub of ActiveRecord method
  def save!
    true
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
end

class Word
  attr_accessor :string, :sentence_index, :tag_count, :tags

  def initialize
    @tags = []
  end

  def tag_by_string(str)
    @tags.each do |t|
      return t if str == t.clean_out_tag
    end

    return nil
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
  #instantiate inactive evaluator
  evaluator = Evaluator.new($eval_file)

  # parse options
  opts = GetoptLong.new(
          ["--eval", "-e", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
      when "--eval":
        # activate evaluator
        evaluator.evaluation_file = arg.inspect
    end
  end

  # o.each_line do |line|
  #   $stderr.puts line
  # end

  # output and merge disambigious words
  disambiguator = Disambiguator.new(evaluator)
  disambiguator.disambiguate
end
