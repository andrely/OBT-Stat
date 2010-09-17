class InputWriter
  def write(word, tag)
    word.preamble.each { |str| puts str } if word.preamble
    puts word.input_string
    puts tag.input_string
  end
end

class VRTWriter
  def write(word, tag)
    puts "#{word.normalized_string}\t#{tag.lemma}\t#{tag.clean_out_tag}"
  end
end
