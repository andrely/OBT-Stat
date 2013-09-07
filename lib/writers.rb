module TextlabOBTStat

  ##
  # @abstract Subclass and override {#write}, {#write_postamble} and #{write_sentence_delimiter} to implement an output
  #   formatting class that can be passed to Disambiguator.
  class Writer
    ##
    # @param [IO, StringIO] file IO instance to which output is written.
    def initialize(file=$stdout)
      @file = file
    end

    ##
    # Format and output the given word, its annotation and preamble text if needed.
    #
    # @param [Word] word
    def write(word)
      raise NotImplementedError
    end

    ##
    # Format and output postamble text after annotated text if needed.
    #
    # @param [Text] text
    # @todo Doesn't need to use the word for current supported formats. Some formats (treetagger) do, but then
    #   Disambiguator needs to call the Writer interface differently eg. in Disambiguator.disambiguate_word.
    def write_postamble(text)
      raise NotImplementedError
    end

    ##
    # Format and output a sentence delimiter if needed.
    #
    # @param [Word] word The last Word instance written.
    def write_sentence_delimiter(word)
      raise NotImplementedError
    end
  end

  class InputWriter < Writer
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

  class VRTWriter < Writer
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

  class MarkWriter < Writer
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
      @file.puts text.postamble
    end

    #noinspection RubyUnusedLocalVariable
    def write_sentence_delimiter(word)
    end
  end
end
