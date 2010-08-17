require 'iconv'
require 'lib/disambiguation_context'
require 'lib/disambiguation_unit'
require 'lib/lemma_model'

class Disambiguator
  attr_accessor :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx,
    :text_idx, :input_file, :lemma_model

  def initialize(evaluator)
    @evaluator = evaluator
  end

  def self.run_hunpos(text)
    info_message($hunpos_command + " " + $hunpos_default_model)
    
    hunpos_output = []
    
    File.open('temp', 'w') do |f|
      text.sentences.each do |s|
        s.words.each do |w|
           f.puts w.normalized_string.downcase
        end

        f.puts
       end
    end

    io = IO.popen("#{$hunpos_command} #{$hunpos_default_model} < temp", 'r+')
    
    io.each_line do |line|
       line = line.chomp

      # skip empty lines separating sentences
      if not line == ""
        hun_word, hun_tag = line.split(/\s/)
        hunpos_output.push([hun_word, hun_tag])
      end
    end

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
      @text = OBNOText.parse $stdin
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
    context.eval = @evaluator.evaluation_data
    context.eval_active = @evaluator.active
    
    while not context.at_end?
      disambiguate_word(context)
      context.advance
    end

    @evaluator.print_summary($stderr)
  end

  def disambiguate_word(context)
    word = context.current(:input)
    hun = context.current(:hunpos)
    eval = context.current(:eval)

    word_s = word.normalized_string.downcase
    hun_s = hun.first
    
    # if there is no eval corpus loaded eval is nil and we
    # substitute the current word for synchronization
    # checking
    if eval
      eval_s = eval.first.downcase
    else
      eval_s = word_s.downcase
    end
    
    if not (word_s == eval_s and word_s == hun_s)
      out_words = context.synchronize

      out_words.each do |w|
        raise RuntimeError if w.ambigious?

        tag = w.get_correct_tag

        puts "#{w.normalized_string}\t#{tag.lemma}\t#{tag.clean_out_tag}"
      end
    else
      unit = DisambiguationUnit.new(word, eval, hun, @evaluator, context)
      output = unit.resolve
      
      puts "#{output[0]}\t#{output[1]}\t#{output[2]}"

    end
        
    return true
  end

  def self.token_word_count(token)
    return token.split('_').count
  end
end
