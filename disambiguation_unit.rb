require 'tracer'

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
        lemmas = candidates.collect { |t| t.lemma }

        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)

        if @eval
          @evaluator.mark_lemma lemma, @context
          $tracer.message "CORRECT #{@evaluator.get_data(@context.eval_idx).join("\t")}"
        end
        
        return [@input.output_string, lemma, @hunpos[1]]
      else
        # no match, choose the word with the best lemma

        # candidates = @input.tags.find_all { |t| t.clean_out_tag == @hunpos[1] }
        candidates = @input.tags.find_all { |t| t.equal(@hunpos[1]) }
        lemmas = candidates.collect { |t| t.lemma }

        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)

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
            
        return [@input.output_string, tag.lemma, tag.clean_out_tag]
      end
    else
      raise RuntimeError if @input.tags.length > 1
      return [@input.output_string, @input.tags.first.lemma, @input.tags.first.clean_out_tag]
    end
  end
end
