require 'tempfile'

class Disambiguator
  attr_accessor :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx,
    :text_idx, :input_file, :lemma_model

  def initialize(evaluator)
    @evaluator = evaluator
  end

  def self.run_hunpos(text)
    info_message($hunpos_command + " " + $hunpos_default_model)
    
    hunpos_output = []

    in_file = Tempfile.new('hunpos-in')

    # open in binary to ensure unix line terminators on windows
    File.open(in_file.path, 'wb') do |f|
      text.sentences.each do |s|
        s.words.each do |w|
           f.puts w.normalized_string.downcase
        end

        f.puts
       end
    end

    io = IO.popen("#{$hunpos_command} #{$hunpos_default_model} < #{in_file.path}", 'r+')
    
    io.each_line do |line|
       line = line.chomp

      # skip empty lines separating sentences
      if not line == ""
        hun_word, hun_tag = line.split(/\s/)
        hunpos_output.push([hun_word, hun_tag])
      end
    end

    in_file.delete()
    io.close

    return hunpos_output
  end

  # This function drives the disambiguation loop over
  # the tokens in the OB annotated input.
  def disambiguate
    context = DisambiguationContext.new

    # get input
    @text = nil
    if @input_file.nil?
      @text = OBNOText.parse($stdin, $static_punctuation)
    else
      File.open(@input_file) do |f|
        @text = OBNOText.parse f
      end
    end

    # run Hunpos
    info_message "Start running HunPos"
    @hunpos_output = Disambiguator.run_hunpos @text
    info_message "Finished running HunPos"

    # build lemma model
    info_message "Building lemma model"
    $lemma_model = LemmaModel.new(@evaluator)
    $lemma_model.read_lemma_model $default_lemma_model
    info_message "Finished building lemma model"
    
    # store all data in context
    context.input = @text.words
    context.hunpos = @hunpos_output
    
    while not context.at_end?
      disambiguate_word(context)
      context.advance
    end
    
    $writer.write_postamble(@text)

    @evaluator.print_summary($stderr)
  end

  def disambiguate_word(context)
    word = context.current(:input)
    hun = context.current(:hunpos)

    word_s = word.normalized_string.downcase
    hun_s = hun.first
    
    if not word_s == hun_s
      out_words = context.synchronize

      out_words.each do |w|
        raise RuntimeError if w.ambigious?

        $writer.write(w)
      end
    else
      unit = DisambiguationUnit.new(word, hun, @evaluator, context)
      word = unit.resolve
      
      if @evaluator.active
        correct_tag = word.get_correct_tag
        
        if word.get_selected_tag.correct
          @evaluator.mark_global_correct
        end
        
        if correct_tag
          if word.get_selected_tag.clean_out_tag.downcase ==
              correct_tag.clean_out_tag.downcase
            @evaluator.mark_global_correct_tag
          end
          
          if word.get_selected_tag.lemma.downcase ==
              word.get_correct_tag.lemma.downcase
            @evaluator.mark_global_correct_lemma
          end
        else
          @evaluator.mark_ob_non_coverage
        end
      end

      $writer.write(word)

      if word.end_of_sentence?
        $writer.write_sentence_delimiter(word)
      end
    end
        
    return true
  end

  def self.token_word_count(token)
    return token.split('_').count
  end
end
