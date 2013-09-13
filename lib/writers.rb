module TextlabOBTStat

  # @abstract Subclass and override {#write}, {#write_postamble} and potentially
  #   {#write_sentence_header}/#{write_sentence_footer} to implement an output
  #   formatting class that can be passed to Disambiguator.
  class Writer

    # @option opts [IO, StringIO] file IO instance to which output is written.
    # @option opts [Symbol] xml Include sentence segmentation tags in output
    def initialize(opts={})
      @file = opts[:file] || $stdout
      @xml = opts[:xml] || nil
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

    # Write sentence start marker based on the passed Sentence instance.
    # @param [Sentence] sentence Current sentence.
    def write_sentence_header(sentence)
      # default is to output XML sentence delimiter if requested
      if @xml
        @file.puts(xml_start_tag(sentence))
      end
    end

    # @private
    def xml_start_tag(sentence)
      if sentence.attrs
        attr_str = sentence.attrs.keys.collect { |attr| "#{attr.to_s}=\"#{sentence.attrs[attr]}\"" }.join(" ")
        "<s #{attr_str}>"
      else
        "<s>"
      end
    end

    # Write sentence end marker based on the passed Sentence instance.
    # @param [Sentence] sentence Current sentence.
    def write_sentence_footer(sentence)
      # default is to output XML sentence delimiter if requested
      if @xml
        @file.puts("</s>")
      end
    end
  end

  # Echo the input as closely as possible.
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


    def write_sentence_header(sentence)
      super

      # include XML sentence tags even if they're not asked for
      # @todo tag may precede preamble even if this differs from input
      if @xml.nil? and sentence.attrs
        @file.puts(xml_start_tag(sentence))
      end
    end

    def write_sentence_footer(sentence)
      super

      # include XML sentence tags even if they're not asked for
      if @xml.nil? and sentence.attrs
        @file.puts("</s>")
      end
    end
  end

  # Tabular format with token, tag and lemma tab separated
  class VRTWriter < Writer
    def write(word)
      tag = word.get_selected_tag
      @file.puts "#{word.output_string}\t#{tag.lemma}\t#{tag.clean_out_tag}"
    end

    #noinspection RubyUnusedLocalVariable
    def write_postamble(text)
      # No postamble in VRT output
    end

    def write_sentence_header(sentence)
      super(sentence)
    end

    def write_sentence_footer(sentence)
      super(sentence)

      # empty line separates sentences unless xml sentence delimiters are requested.
      @file.puts unless @xml
    end
  end

  # @deprecated
  class MarkWriter < InputWriter
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
  end
end
