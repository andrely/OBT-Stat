class DisambiguationUnit
  def initialize(input, hunpos, context)
    @input = input
    @hunpos = hunpos
    
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
        $tracer.message "SELECTED HUNPOS #{@hunpos[1]}"
        
        # disambiguate lemma from tag/lemmas that correspond the disambiguated tag
        # candidates = @input.tags.find_all { |t| t.clean_out_tag == @hunpos[1] }
        candidates = @input.tags.find_all { |t| t.equal(@hunpos[1]) }
        if candidates.count > 1
          lemmas = candidates.collect { |t| t.lemma }
          $tracer.message "LEMMA CANDIDATES " + lemmas.join(' ')

          lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)
          $tracer.message "LEMMA CHOSEN " + lemma

          candidates = candidates.find_all { |t| t if t.lemma.downcase == lemma.downcase }
        end

        candidates.first.selected = true
        # puts 'ARBITRARY SELECTION' if candidates.count > 1

        return @input
      else
        # no match, choose the word with the best lemma
        candidates = @input.tags.find_all { |t| t.lemma }
        lemmas = candidates.collect { |t| t.lemma }
        $tracer.message "LEMMA CANDIDATES " + lemmas.join(' ')
        
        lemma = $lemma_model.disambiguate_lemma(@input.string, lemmas)
        $tracer.message "LEMMA CHOSEN " + lemma

        tags = @input.tags.find_all { |t| t.lemma == lemma }

        # take the first tag with the correct lemma
        tag = tags.first
        # or the first of all OB tags if none with the chosen lemma
        # is available
        tag = @input.tags.first if tag.nil?
        # puts 'ARBITRARY SELECTION' if tag.nil?

        tag.selected = true

        $tracer.message "SELECTED OB #{tag.lemma} #{tag.clean_out_tag}"

        return @input
      end
    else
      raise RuntimeError if @input.tags.length > 1

      @input.tags.first.selected = true

      return @input
    end
  end
end
