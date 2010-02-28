class Evaluator
  attr_reader :evaluation_file, :active
  attr_accessor :evaluation_data

  def initialize(evaluation_file=nil)
    @evaluation_file = evaluation_file
    @active = nil

    @ambiguity_count = 0
    @hunpos_resolved_count = 0
    @ob_resolved_count = 0
    @collocation_unresolved_count = 0
    @unaligned_eval_count = 0
    @hunpos_correct_count = 0
    @lemma_correct_count = 0
    
    if evaluation_file
      @evaluation_data = read_eval_data
      @active = true
    end
  end
  
  def read_eval_data
    data = []

    File.open(@evaluation_file) do |file|
      file.each_line do |line|
        if line.chop != ""
          word, tag, lemma  = line.split("\t")
          raise RuntimeError if (word == "") or (tag == "") or (lemma == "")
          data << [word.strip, tag.strip, lemma.strip]
        end
      end
    end

    return data
  end

  def validate_eval_data(word, index)
    eval_word = @evaluation_data[index][0]
    
    # some special massaging to handle discrepancies between
    # old and new OB versions
    
    # training corpus has a space netween numbers and the percent sign
    # eg. "30 %" but in present OB output this space is removed ("30%")
    eval_word = eval_word.gsub(" %", "%")

    $stderr.puts "#{word.string} #{eval_word}"

    return word.string == eval_word
  end

  def get_data(index)
    return @evaluation_data[index]
  end

  def evaluation_file=(filename)
    @evaluation_file = filename
    @active = true
  end

  def mark_ambiguity
    @ambiguity_count += 1
  end

  def mark_hunpos_resolved
    mark_ambiguity
    @hunpos_resolved_count += 1
  end

  def mark_ob_resolved
    mark_ambiguity
    @ob_resolved_count += 1
  end

  def mark_unresolvable_collocation
    @collocation_unresolved_count += 1
  end

  def mark_hunpos_correct
    @hunpos_correct_count += 1
  end

  def mark_lemma_correct
    @lemma_correct_count += 1
  end

  def mark_unaligned_eval
    @unaligned_eval_count += 1
  end

  def print_summary(out)
    info_message "Ambiguities: #{@ambiguity_count}"
    info_message "- Resolved by HunPos: #{@hunpos_correct_count}/#{@hunpos_resolved_count}"
    info_message "- Resolved with random OB tag: #{@ob_resolved_count}"
    info_message "Correctly resolved lemmas: #{@lemma_correct_count}"
    info_message "Collocations: #{@collocation_unresolved_count}"
    info_message "Unaligned evaluation tokens: #{@unaligned_eval_count}"
  end
end

class DisambiguationResult
  def initialize(index, word, tag, source)
    @index = index
    @word = word
    @tag = tag
    @source = source # :hunpos or :heuristic
  end

  
end
