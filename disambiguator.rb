require 'iconv'
require 'disambiguation_context'
require 'disambiguation_unit'

class Disambiguator
  attr_accessor :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx,
    :text_idx, :input_file, :lemma_model

  def initialize(evaluator)
    @evaluator = evaluator

    @hunpos_seek_buf = nil
  end

  def run_hunpos
    info_message($hunpos_command + " " + $hunpos_default_model)
    
    @hunpos_output = []
    
    File.open('temp', 'w') do |f|
      @text.sentences.each do |s|
        s.words.each do |w|
          # f.puts Iconv.conv("ISO-8859-1", "UTF-8", w.normalized_string)
          f.puts w.normalized_string
        end

        f.puts
        info_message ".", nil
      end
    end

    io = IO.popen("#{$hunpos_command} #{$hunpos_default_model} < temp", 'r+')
    
    io.each_line do |line|
      info_message "-", nil
        
      line = line.chomp

      # skip empty lines separating sentences
      if not line == ""
        hun_word, hun_tag = line.split(/\s/)
        @hunpos_output.push([hun_word, hun_tag])
      end
    end

    io.close
 
    info_message "" # just a finishing newline
    info_message "Finished running HunPos"
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

    # build lemma model
    $lemma_model = LemmaModel.new
    
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

    word_s = word.normalized_string
    hun_s = hun.first

    if eval
      eval_s = eval.first
    else
      eval_s = word_s
    end

    if not (word_s == eval_s and word_s == hun_s)
      # try to append next eval token
      eval_cur = context.pos(:eval)
      eval_next = context.at(:eval, eval_cur + 1)

      if eval_s + eval_next[0] == word_s and word_s == hun_s
        # if this works advance eval index by 1
        context.eval_idx += 1
      elsif eval_s + '_' + eval_next[0] == word_s and word_s == hun_s
        context.eval_idx += 1
      else
        # if not throw error
        info_message "#{word_s} : #{eval_s} : #{hun_s}"
        raise RuntimeError
      end
    end

    unit = DisambiguationUnit.new([word], [eval], [hun], @evaluator, context.input_idx)
    output = unit.resolve

    output.each { |o| puts "#{o[0]}\t#{o[1]}\t#{o[2]}"}
        
    return true
  end
end
