def counts_to_indices(counts)
  rval = []
  index = 0

  counts.each do |c|
    c.times do |i|
      rval << index 
    end

    index += 1
  end

  return rval
end

def info_message(msg)
  $stderr.puts msg
end

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

class DisambiguationUnit
  def initialize(input_analysis, eval_analysis, hunpos_analysis, evaluator)
    @input_analysis = input_analysis
    @eval_analysis = eval_analysis
    @hunpos_analysis = hunpos_analysis

    @input_length = @input_analysis.length
    @eval_length = @eval_analysis.length
    @hunpos_length = @hunpos_analysis.length

    @evaluator = evaluator
    
    # if we're passed more than one Hunpos tokens
    # we have a collocation in the input or eval tokens
    @complex_disambiguation = @hunpos_length > 1
  end

  def resolve
    if @complex_disambiguation
      resolve_complex
    else
      resolve_simple
    end
  end

  def resolve_complex
    input_lengths = @input_analysis.collect { |i| i.string.split(/\s/).length }
    eval_lengths = @eval_analysis.collect { |e| e.first.split(/\s/).length }
    
    # sanity checking
    input_indices = counts_to_indices(input_lengths)
    raise RuntimeError if not input_indices.length == @hunpos_length

    hunpos_alignment = align_input_hunpos
    
    rval = []
    
    @input_length.times do |i|
      input = @input_analysis[i]
      hunpos = @hunpos_analysis[hunpos_alignment[i]]
      
      # if there is a hole in the input/hunpos alignment then there is a collocation
      # in the input that cannot be disambiguated by hunpos
      if ((i + 1) < @input_analysis.length) and
          (hunpos_alignment[i] - hunpos_alignment[i + 1]) > 1
        @evaluator.mark_unresolvable_collocation
        rval << [input.string, input.tags.first.clean_out_tag]
        
      elsif (i == @input_length - 1) and # hole at end
          (hunpos_alignment[i] < @hunpos_length)
        @evaluator.mark_unresolvable_collocation
        rval << [input.string, input.tags.first.clean_out_tag]

      # if not resolve the input as normal
      else
        rval << resolve_input_hunpos(input, hunpos, find_aligned_eval(i))
      end
    end

    return rval
  end

  def resolve_simple
    raise RuntimeError if @input_length > 1 or @eval_length > 1
    
    return [resolve_input_hunpos(@input_analysis.first, @hunpos_analysis.first, @eval_analysis.first)]
  end

  def resolve_input_hunpos(input, hunpos, eval)
    if input.ambigious?
      if input.match_clean_out_tag(hunpos[1])
        # hunpos match
        @evaluator.mark_hunpos_resolved
        @evaluator.mark_hunpos_correct if hunpos[1] == eval[1] if eval # eval is nil if unaligned
        return [input.string, hunpos[1]]
      else
        # no watch, return "random" tag
        @evaluator.mark_ob_resolved
        return [input.string, input.tags.first.clean_out_tag]
      end
    else
      raise RuntimeError if input.tags.length > 1
      return [input.string, input.tags.first.clean_out_tag]
    end
  end

  def align_input_hunpos
    rval = []
    index = 0

    @input_analysis.each do |input|
      rval << index
      index += input.word_count
    end

    return rval
  end

  def find_aligned_eval(index)
    # find input word count up to and including the index
    input_word_count = @input_analysis[0..index].collect { |w| w.word_count }.sum

    eval_word_count = 0
    eval_index = 0
    
    # traverse the eval words until we have the as many words
    until eval_word_count >= input_word_count
      eval = @eval_analysis[index]
      eval_word_count += eval.first.split(/\s/).length
      eval_index += 1
    end

    if eval_word_count == input_word_count and
        @input_analysis[index].word_count == @eval_analysis[eval_index].first.split(/\s/).length
      return @eval_analysis[eval_index]
    else
      @evaluator.mark.unaligned_eval
      return nil
    end

  end
end

class Disambiguator
  attr_accessor :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx, :text_idx, :input_file

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
    OBNOText.parse @text, File.open(@input_file).read

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
    # get current surface token and the number of words they're composed of
    word = context.current(:input)
    word_length = word.string.split(/\s/).length
    eval = context.current(:eval)
    eval_length = eval.first.split(/\s/).length
    hun = context.current(:hunpos)

    # if one of the current tokens consists of more than one word, correct for the
    # difference be getting additional tokens from the other data sources and
    # update their indices accordingly
    if word_length > eval_length # word has more than one, and most, words 
      hun = context.current(:hunpos, word_length)
      eval = context.current(:eval, word_length - eval_length + 1)

      context.hun_idx += word_length - 1
      context.eval_idx += word_length - eval_length

      # normalize all token sets to arrays
      word = [word]

    elsif eval_length > word_length # eval has more than one, and most words
      hun = context.current(:hunpos, eval_length)
      word = context.current(:input, eval_length - word_length + 1)

      context.hun_idx += eval_length - 1
      context.input_idx += eval_length - word_length

      # normalize all token sets to arrays
      eval = [eval]
    elsif word_length > 1 and word_length == eval_length
      hun = context.current(:hunpos, word_length)

      context.hun_idx += word_length - 1

      # normalize all token sets to arrays
      word = [word]
      eval = [eval]
    else
      # normalize all token sets to arrays
      word = [word]
      eval = [eval]
      hun = [hun]
    end
    
    # collect surface forms and ensure that they are the same across the
    # different data arrays
    word_s = word.collect { |w| w.string }.join(' ')
    eval_s = eval.to_a.collect { |e| e.first }.join(' ')
    hun_s = hun.collect { |h| h.first }.join(' ')
    
    # puts "#{word_s} - #{eval_s} - #{hun_s}"

    if not (word_s == eval_s and word_s == hun_s)
      raise RuntimeError, "Token data out of sync "
    end

    # now the surface form is in sync and we have all the needed token data
    unit = DisambiguationUnit.new(word, eval, hun, @evaluator)
    output = unit.resolve

    output.each { |o| puts "#{o[0]}\t#{o[1]}"}
        
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
