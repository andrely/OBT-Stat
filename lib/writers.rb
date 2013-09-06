class InputWriter
  ##
  # @param [IO, StringIO] file IO instance to which output is written.
  def initialize(file=$stdout)
    @file = file
  end

  def write(word)
    tag = word.get_selected_tag

    word.preamble.each { |str| @file.puts str } if word.preamble
    @file.puts word.input_string
    @file.puts tag.input_string
  end

  def write_postamble(text)
    @file.puts text.postamble
  end

  #noinspection RubyUnusedLocalVariable
  def write_sentence_delimiter(word)
  end
end

class VRTWriter
  ##
  # @param [IO, StringIO] file IO instance to which output is written.
  def initialize(file=$stdout)
    @file = file
  end

  def write(word)
    tag = word.get_selected_tag
    @file.puts "#{word.output_string}\t#{tag.lemma}\t#{tag.clean_out_tag}"
  end

  #noinspection RubyUnusedLocalVariable
  def write_postamble(text)
    # No postamble in VRT output
  end

  # empty line separates sentences
  #noinspection RubyUnusedLocalVariable
  def write_sentence_delimiter(word)
    @file.puts
  end
end

class MarkWriter
  ##
  # @param [IO, StringIO] file IO instance to which output is written.
  def initialize(file=$stdout)
    @file = file
  end

  def write(word)
    word.preamble.each { |str| @file.puts str } if word.preamble
    @file.puts word.input_string

    word.tags.each do |tag|
      @file.write tag.input_string.rstrip

      if tag.selected
        @file.write ' <SELECTED>'
      end

      if tag.selected and not tag.correct
        @file.write ' <ERROR>'
      end

      @file.puts
    end
  end

  def write_postamble(text)
    puts text.postamble
  end

  #noinspection RubyUnusedLocalVariable
  def write_sentence_delimiter(word)
  end
end
