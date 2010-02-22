class DisambiguationUnit
  def initialize(input_analysis, eval_analysis, hunpos_analysis, evaluator, pos)
    @input_analysis = input_analysis
    @eval_analysis = eval_analysis
    @hunpos_analysis = hunpos_analysis

    @input_length = @input_analysis.length
    @eval_length = @eval_analysis.length
    @hunpos_length = @hunpos_analysis.length

    @evaluator = evaluator

    @pos = pos
    
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
    # complex resolution probably not needed
    # disabling this code

    raise RuntimeError
    
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
    # TODO select and output lemmas
    if input.ambigious?
      $log_fd.puts "Amibigious word \"#{input.string}\" at #{@pos}}"
      input.tags.each do |t|
        $log_fd.puts "OB: #{t.lemma} #{t.clean_out_tag}"
      end
      $log_fd.puts "HUNPOS: #{hunpos[1]} (#{hunpos[0]})"
      
      if input.match_clean_out_tag(hunpos[1])
        # hunpos match
        @evaluator.mark_hunpos_resolved
        
        $log_fd.puts "SELECTED HUNPOS #{eval[1] if eval} #{hunpos[1]}"
        
        @evaluator.mark_hunpos_correct if hunpos[1] == eval[1] if eval # eval is nil if unaligned

        candidates = input.tags.find_all { |t| t.clean_out_tag == hunpos[1] }
        lemmas = candidates.collect { |t| t.lemma }

        lemma = $lemma_model.disambiguate_lemma(input.string, lemmas)
        
        return [input.string, lemma, hunpos[1]]
      else
        # no watch, return "random" tag
        @evaluator.mark_ob_resolved

        $log_fd.puts "SELECTED OB #{input.tags.first.lemma} #{input.tags.first.clean_out_tag}"
        
        return [input.string, input.tags.first.lemma, input.tags.first.clean_out_tag]
      end
    else
      raise RuntimeError if input.tags.length > 1
      return [input.string, input.tags.first.lemma, input.tags.first.clean_out_tag]
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
