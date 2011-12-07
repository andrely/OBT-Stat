class InputWriter
  def write(word)
    tag = word.get_selected_tag
    
    word.preamble.each { |str| puts str } if word.preamble
    puts word.input_string
    puts tag.input_string
  end

  def write_postamble(text)
    puts text.postamble
  end

  def write_sentence_delimiter(word)
  end
end

class VRTWriter
  def write(word)
    tag = word.get_selected_tag
    puts "#{word.output_string}\t#{tag.lemma}\t#{tag.clean_out_tag}"
  end

  def write_postamble(text)
    # No postamble in VRT output
  end

  # empty line separates sentences
  def write_sentence_delimiter(word)
    puts
  end
end

class MarkWriter
  def write(word)
    word.preamble.each { |str| puts str } if word.preamble
    puts word.input_string

    word.tags.each do |tag|
      $stdout.write tag.input_string.rstrip

      if tag.selected
        $stdout.write ' <SELECTED>'
      end

      if tag.selected and not tag.correct
        $stdout.write ' <ERROR>'
      end

      puts
    end
  end

  def write_postamble(text)
    puts text.postamble
  end

  def write_sentence_delimiter(word)
  end
end
