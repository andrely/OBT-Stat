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
    @lemma_hit_count = 0
    @lemma_lookup_count = 0

    @lemma_error_map = { }
    
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

  def mark_lemma(lemma, context)
    eval = context.current(:eval)[2]

    return if eval.nil? or lemma.nil?

    if lemma == eval
      @lemma_correct_count += 1

      return
    end

    if not @lemma_error_map.has_key? eval
      @lemma_error_map[eval] = { lemma => 1 }
    else
      data = @lemma_error_map[eval]
      
      if data[lemma]
        data[lemma] += 1
      else
        data[lemma] = 1
      end
      
    end
  end

  def mark_unaligned_eval
    @unaligned_eval_count += 1
  end

  def mark_lemma_hit
    @lemma_lookup_count += 1
    @lemma_hit_count += 1
  end

  def mark_lemma_miss
    @lemma_lookup_count += 1
  end

  def print_summary(out)
    info_message "Ambiguities: #{@ambiguity_count}"
    info_message "- Resolved by HunPos: #{@hunpos_correct_count}/#{@hunpos_resolved_count}"
    info_message "- Resolved with random OB tag: #{@ob_resolved_count}"
    info_message "Correctly resolved lemmas: #{@lemma_correct_count}"
    info_message "Lemma model hit/use ratio: #{@lemma_hit_count}/#{@lemma_lookup_count}"
    info_message "Collocations: #{@collocation_unresolved_count}"
    info_message "Unaligned evaluation tokens: #{@unaligned_eval_count}"

    @lemma_error_map.each do |k, v|
      data = v.collect do |kk, vv|
        "#{kk} #{vv}"
      end
      info_message "#{k}\t#{data.join("\t")}"
    end
  end
end
