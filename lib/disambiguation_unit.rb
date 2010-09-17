# require 'tracer'

class DisambiguationUnit
  def initialize(input, eval, hunpos, evaluator, context)
    @input = input
    @eval = eval
    @hunpos = hunpos

    @evaluator = evaluator
    
    @context = context
    @pos = context.input_idx
  end

  def resolve
    if @input.ambigious?
      # Tracer output
      $tracer.message "Amibigious word \"#{@input.string}\" at #{@pos}}"
      @input.tags.each do |t|
        $tracer.message "OB: #{t.lemma} #{t.clean_out_tag}"
      end
      $tracer.message "HUNPOS: #{@hunpos[1]} (#{@hunpos[0]})"

      # Hunpos tag matches input
      if @input.match_clean_out_tag(@hunpos[1])
        # hunpos match
        @evaluator.mark_hunpos_resolved
        
        $tracer.message "SELECTED HUNPOS #{@eval[1] if @eval} #{@hunpos[1]}"

        # TODO better checking for evaluation
        if @eval # eval is nil if unaligned
          if @hunpos[1] == @eval[1]
            @evaluator.mark_hunpos_correct
          else
            $tracer.message "HUNPOS CONFUSION #{@eval[1]} +++ #{@hunpos[1]}"
          end
        end
        
        # disambiguate lemma from tag/lemmas that correspond the disambiguated tag
        # candidates = @input.tags.find_all { |t| t.clean_out_tag == @hunpos[1] }
        candidates = @input.tags.find_all { |t| t.equal(@hunpos[1]) }
        if candidates.count > 1
          lemmas = candidates.collect { |t| t.lemma }
          $tracer.message "LEMMA CANDIDATES " + lemmas.join(' ')

          lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)
          $tracer.message "LEMMA CHOSEN " + lemma

          if @eval
            $tracer.message "LEMMA CHOSEN " + lemma + " CORRECT " + @context.current(:eval)[2]
            @evaluator.mark_lemma lemma, @context
            $tracer.message "CORRECT #{@evaluator.get_data(@context.eval_idx).join("\t")}"
          end

          candidates = candidates.find_all { |t| t if t.lemma.downcase == lemma.downcase }
        end
        
        return [@input, candidates.first]
      else
        # no match, choose the word with the best lemma
        candidates = @input.tags.find_all { |t| t.lemma }
        lemmas = candidates.collect { |t| t.lemma }
        $tracer.message "LEMMA CANDIDATES " + lemmas.join(' ')
        
        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)
        $tracer.message "LEMMA CHOSEN " + lemma
        if @eval
          $tracer.message "LEMMA CHOSEN " + lemma + " CORRECT " + @context.current(:eval)[2]
        end
        
        tags = @input.tags.find_all { |t| t.lemma == lemma }

        # take the first tag with the correct lemma
        tag = tags.first
        # or the first of all OB tags if none with the chosen lemma
        # is available
        tag = @input.tags.first if tag.nil?

        @evaluator.mark_ob_resolved

        $tracer.message "SELECTED OB #{tag.lemma} #{tag.clean_out_tag}"

        if @eval
          # if tag.clean_out_tag == @eval[1]
          if tag.equal(@eval[1])
            @evaluator.mark_ob_correct
          else
            $tracer.message "OB CONFUSION #{@eval[1]} +++ #{tag.clean_out_tag} ??? #{@hunpos[1]}"
          end
          
          # do not count correct lemmas that was not available from OB
          @evaluator.mark_lemma(lemma, @context) if not tags.nil?
          $tracer.message "CORRECT #{@evaluator.get_data(@context.eval_idx).join("\t")}"
        end
            
        return [@input, tag]
      end
    else
      raise RuntimeError if @input.tags.length > 1

      return [@input, @input.tags.first]
    end
  end
end
