class Evaluator
  attr_reader :evaluation_file
  attr_accessor :evaluation_data

  def initialize(evaluation_file)
    @evaluation_file = evaluation_file
    @active = nil

    @ambiguity_count = 0
    @hunpos_resolved_count = 0
    @ob_resolved_count = 0

    @evaluation_data = read_eval_data
  end
  
  def read_eval_data
    data = []

    File.open(@evaluation_file) do |file|
      file.each_line do |line|
        if line.chop != ""
          word, tag = line.split(/\s/)
          data << [word, tag]
        end
      end
    end

    return data
  end

  def validate_eval_data(word, index)
    eval_word = @evaluation_data[index][0]

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

  def print_summary(out)
    out.puts "Ambiguities: #{@ambiguity_count}"
    out.puts "- Resolved by HunPos: #{@hunpos_resolved_count}"
    out.puts "- Resolved by OB: #{@ob_resolved_count}"
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
