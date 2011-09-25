class Evaluator
  attr_reader :evaluation_file, :active
  attr_accessor :evaluation_data

  def initialize(active = nil)
    @active = active

    @ambiguity_count = 0
    @word_count = 0
    @global_correct_count = 0
    @global_correct_lemma_count = 0
    @global_correct_tag_count = 0
    @hunpos_resolved_count = 0
    @ob_resolved_count = 0
    @collocation_unresolved_count = 0
    @unaligned_eval_count = 0
    @hunpos_correct_count = 0
    @ob_correct_count = 0
    @lemma_correct_count = 0
    @lemma_hit_count = 0
    @lemma_lookup_count = 0
    
    @ob_non_coverage_count = 0
    
    @lemma_error_map = { }
    @print_lemma_map = false
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

  def mark_ob_correct
    @ob_correct_count += 1
  end

  def mark_lemma_correct
    @lemma_correct_count += 1
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

  def mark_word
    @word_count += 1
  end

  def mark_global_correct
    @global_correct_count += 1
  end

  def mark_global_correct_lemma
    @global_correct_lemma_count += 1
  end
  
  def mark_global_correct_tag
    @global_correct_tag_count += 1
  end

  def mark_ob_non_coverage
    @ob_non_coverage_count += 1
  end

  def print_summary(out)
    if @active
      out.puts "Ambiguities: #{@ambiguity_count}/#{@word_count}"
      out.puts "- Resolved by HunPos: #{@hunpos_correct_count}/#{@hunpos_resolved_count}"
      out.puts "- Resolved with random OB tag: #{@ob_correct_count}/#{@ob_resolved_count}"
      out.puts "Correctly resolved lemmas: #{@lemma_correct_count}"
      out.puts "Lemma model hit/use ratio: #{@lemma_hit_count}/#{@lemma_lookup_count}"
      out.puts
      out.puts "Precision #{@global_correct_count}/#{@word_count}, #{(@global_correct_count * 1.0) / @word_count}"
      out.puts "Tag precision #{@global_correct_tag_count}/#{@word_count}. #{(@global_correct_tag_count *1.0) / @word_count}"
      out.puts "Lemma precision #{@global_correct_lemma_count}/#{@word_count}. #{(@global_correct_lemma_count * 1.0)/@word_count}"
      out.puts "OBT non-coverage #{@ob_non_coverage_count}"
      if @print_lemma_map
        @lemma_error_map.each do |k, v|
          data = v.collect do |kk, vv|
            "#{kk} #{vv}"
          end
          out.puts "#{k}\t#{data.join("\t")}"
        end
      end
    end
  end
end
