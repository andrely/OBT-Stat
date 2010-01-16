# Data structure for keeping all the disambiguation data, and current indices
# into it
#
# The data:
# input: OB annotated input text, Array of Sentence instances
# hunpos: Hunpos annotated input text, Array of token/tag string pairs
# eval: optional evaluation data, Array of token/tag pairs
#
# The hunpos data contains one item per "word", but the input and eval data
# may contain items that are several collocated words that are treated as one
# token. The _idx variables keeps track of current position for each data array
# to the current position in the input text. This function advances these counters,
# but it is the responsibility of disambiguate_word() to make sure the counters
# account for discrepancies between the data arrays.
class DisambiguationContext
  attr_accessor :input, :hunpos, :eval, :input_idx, :hun_idx, :eval_idx
  
  def initialize
    @input_idx = 0
    @hun_idx = 0
    @eval_idx = 0
  end
  
  # advances all data indices with one, pointing all data arays to the next token
  def advance
    @input_idx += 1
    @hun_idx += 1
    @eval_idx += 1
  end
  
  # returns true if at the end of all data arrays
  def at_end?
    # do we point beyond the end of any of our data arrays ?
    if (@input_idx == @input.length) or (@hun_idx == @hunpos.length) or (@eval_idx == @eval.length)

      # if we're not at the end of all of them we've gone out of sync somewhere
      if not ((@input_idx == @input.length) and (@hun_idx == @hunpos.length) and (@eval_idx == @eval.length))
        raise "End of data out of sync #{@input.length - @input_idx}, #{@hunpos.length - @hun_idx}, #{@eval.length - @eval_idx}"
       else
        return true
      end
    end

    return nil
  end
  
  def at(dataspec, index)
    case dataspec
    when :input
      return @input[index]
    when :eval
      return @eval[index]
    when :hunpos
      return @hunpos[index]
    end

    raise ArgumentError, "Illegal dataspec"
  end

  def pos(dataspec)
    case dataspec
    when :input
      return @input_idx
    when :eval
      return @eval_idx
    when :hunpos
      return @hun_idx
    end

    raise ArgumentError, "Illegal dataspec"
  end

  def current(dataspec, length = nil)
    if length
      pos = pos(dataspec)
      return length.times.collect { |i| at(dataspec, pos + i) }
    else
      case dataspec
      when :input
        return @input[@input_idx]
      when :eval
        return @eval[@eval_idx]
      when :hunpos
        return @hunpos[@hun_idx]
      end

      raise ArgumentError, "Illegal dataspec"

    end
  end
end

class Disambiguator
  attr_accessor :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx, :text_idx

  def initialize(evaluator)
    @evaluator = evaluator

    @hunpos_seek_buf = nil
  end

  def run_hunpos
    # run hunpos
    i, @hunpos_stream, e = Open3.popen3 $hunpos_command
    
    @text.sentences.each do |s|
      s.words.each do |w|
        # split opp collocations from OB, eg. "i forbifarten"
        i.puts w.string.gsub(/\s/, "\n")
      end

      i.puts
    end

    # close input first or Hunpos will wait for more before output
    i.close
 
    @hunpos_output = []
    @hunpos_stream.each_line do |line|
      line = line.chomp

      # skip empty lines separating sentences
      if not line == ""
        hun_word, hun_tag = line.split(/\s/)
        @hunpos_output.push([hun_word, hun_tag])
      end
    end
    
    # closing error stream here works
    e.close   
  end

  # This function drives the disambiguation loop over
  # the tokens in the OB annotated input.
  def disambiguate
    context = DisambiguationContext.new

    # get input
    @text = Text.new
    OBNOText.parse @text, ARGF.read

    # run Hunpos
    run_hunpos
    
    # store all data in context
    context.input = @text.words
    context.hunpos = @hunpos_output
    context.eval = @evaluator.evaluation_data
    
    while not context.at_end?
      disambiguate_word(context)
      context.advance
    end

    @evaluator.print_summary($stderr)
  end

  def disambiguate_word(context)
    # just make sure each data index is advanced properly
    word = context.current(:input).string
    word_length = word.split(/\s/).length
    eval = context.current(:eval).first
    eval_length = eval.split(/\s/).length
    hun = context.current(:hunpos).first

    if word_length > 1
      hun = context.current(:hunpos, word_length).collect { |x| x.first }.join(' ')

      eval = context.current(:eval, word_length - eval_length + 1).collect { |x| x.first }.join(' ')

      context.hun_idx += word_length - 1
      context.eval_idx += word_length - eval_length

    elsif eval_length > 1
      hun = context.current(:hunpos, eval_length).collect { |x| x.first }.join(' ')
      word = context.current(:input, eval_length - word_length + 1).collect { |x| x.string }.join(' ')

      context.hun_idx += eval_length - 1
      context.input_idx += eval_length - word_length

    end
    
    if not word == eval and word == hun
      raise RuntimeError, "Token data out of sync "
    end

    puts "#{word} - #{eval} - #{hun}"
        
    return true
  end

#   def disambiguate_word(word)
#    hun_word, hun_tag = @hunpos_output[@hun_idx]
      
#     raise RuntimeError, "Invalid hunPos input" if not validate_word(word)
#     raise RuntimeError, "Invalid eval input" if not @evaluator.validate_eval_data(word, @text_idx)

#     selected_tag = nil

#     # not ambigious
#     if word.tags.count == 1
#       selected_tag = word.tags.first

#     # ambigious
#     else
#       # fetch tags
#       tags = word.tags.collect {|t| t.clean_out_tag}

#       # use hunpos tag if found, just take the first tag otherwise
#       if tags.include? hun_tag
#         $stderr.puts "ambiguity hunpos tag #{hun_tag} chosen"
#         @evaluator.mark_hunpos_resolved

#         selected_tag = word.tag_by_string(hun_tag)

#         raise RuntimeError if selected_tag.nil?
#       else
#         $stderr.puts "ambiguity ob tag #{word.tags.first.clean_out_tag} chosen"
#         @evaluator.mark_ob_resolved

#         selected_tag = ob_select_tag(word.tags)
#       end
#     end

#     puts word.string + "\t" + selected_tag.clean_out_tag + "\t" + selected_tag.lemma
#   end

  # Selects a tag from available tags generated by OB heuristically
  def ob_select_tag(ob_tags)
    # Current heuristic is to just select the first tag
    return ob_tags.first
  end
  
  def validate_word(word)
    if word.string.include? " "
      words = word.string.split(" ")
      
      hunpos_words = @hunpos_output[@hun_idx...(@hun_idx + words.count)]
      hunpos_words = hunpos_words.collect {|x| x.first}
      raise RuntimeError "Invalid word" if words != hunpos_words
      return false if words != hunpos_words
      
      @hun_idx += words.count - 1
      return true
    else
      hun_word, hun_tag = @hunpos_output[@hun_idx]
      
      return word.string == hun_word
    end
  end

end
