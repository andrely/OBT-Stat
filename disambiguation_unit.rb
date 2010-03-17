require 'tracer'

class DisambiguationUnit
  def initialize(input, eval, hunpos, evaluator, pos)
    @input = input
    @eval = eval
    @hunpos = hunpos

    @evaluator = evaluator

    @pos = pos
  end

  def resolve
    if @input.ambigious?
      $tracer.message "Amibigious word \"#{@input.string}\" at #{@pos}}"
      @input.tags.each do |t|
        $tracer.message "OB: #{t.lemma} #{t.clean_out_tag}"
      end
      $tracer.message "HUNPOS: #{@hunpos[1]} (#{@hunpos[0]})"
      
      if @input.match_clean_out_tag(@hunpos[1])
        # hunpos match
        @evaluator.mark_hunpos_resolved
        
        $tracer.message "SELECTED HUNPOS #{@eval[1] if @eval} #{@hunpos[1]}"

        # TODO better checking for evaluation
        if @eval # eval is nil if unaligned
          @evaluator.mark_hunpos_correct if @hunpos[1] == @eval[1]
        end

        candidates = @input.tags.find_all { |t| t.clean_out_tag == @hunpos[1] }
        lemmas = candidates.collect { |t| t.lemma }

        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)

        if @eval
          @evaluator.mark_lemma_correct if lemma == @eval[2]
        end
        
        return [@input.string, lemma, @hunpos[1]]
      else
        # no match, choose the word with the best lemma

        candidates = @input.tags.find_all { |t| t.clean_out_tag == @hunpos[1] }
        lemmas = candidates.collect { |t| t.lemma }

        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)

        tags = @input.tags.find_all { |t| t.lemma == lemma }

        # take the first tag with the correct lemma
        tag = tags.first
        # or the first of all OB tags if none with the chosen lemma
        # is available
        tag = @input.tags.first if tag.nil?

        @evaluator.mark_ob_resolved
        # do not count correct lemmas that was not available from OB
        if @eval
          @evaluator.mark_lemma_correct if lemma == @eval[2] and not tags.nil?
        end
                
        $tracer.message "SELECTED OB #{tag.lemma} #{tag.clean_out_tag}"
        
        return [(@input.orig_string or @input.string), tag.lemma, tag.clean_out_tag]
      end
    else
      raise RuntimeError if @input.tags.length > 1
      return [(@input.orig_string or @input.string), @input.tags.first.lemma, @input.tags.first.clean_out_tag]
    end
  end
end
