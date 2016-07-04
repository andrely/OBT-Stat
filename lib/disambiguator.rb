require 'rbconfig'
require 'tempfile'

require_relative 'disambiguation_context'
require_relative 'obno_stubs'
require_relative 'obno_text'
require_relative 'lemma_model'
require_relative 'writers'
require_relative 'globals'

module TextlabOBTStat

  # @todo Should disambiguate on original word if present, such that capitalized first words
  #   in a sentence is used. Currently hunpos is passed normailized string.
  # @todo add available? method.
  class Disambiguator

    HUNPOS_UTF8_MODEL_FN = File.join(TextlabOBTStat.root_path,
                                     'models', 'trening-u-flert-d.cor.hunpos_model.utf8')
    HUNPOS_LATIN1_MODEL_FN = File.join(TextlabOBTStat.root_path,
                                       'models', 'trening-u-flert-d.cor.hunpos_model')

    attr_accessor :model_fn, :text, :hunpos_stream, :evaluator, :hunpos_output, :hun_idx,
                  :text_idx, :input_file, :lemma_model

    ##
    # @option opts [Writer] writer
    # @option opts [String] format Input/output encoding (utf-8 or latin1).
    # @option opts [String] model_fn Path to Hunpos model to use instead of the default one.
    # @option opts [IO, StringIO] input_file IO instance to read input from.
    def initialize(opts={})
      @sent_seg = opts[:sent_seg] || :use_static_punctuation
      @writer = opts[:writer] || InputWriter.new(xml: @sent_seg == :xml)
      @format = opts[:format] || "utf-8"
      @model_fn = opts[:model_fn] || Disambiguator.hunpos_default_model_fn(@format)
      @input_file = opts[:input_file] || $stdin

      # info_message "Building lemma model"
      @lemma_model = LemmaModel.new
      # info_message "Finished building lemma model"

      @platform = nil
    end

    ##
    # @private
    def platform
      if @platform.nil?
        host_os = RbConfig::CONFIG['host_os']

        @platform =
            case host_os
              when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                :windows
              when /darwin|mac os/
                :osx
              when /linux/
                :linux
              when /solaris|bsd/
                :unix
              else
                :unknown
            end
      end

      @platform
    end

    ##
    # @private
    def get_hunpos_command
      case platform
        when :osx
          return File.join(TextlabOBTStat.root_path,
                           "hunpos", "hunpos-1.0-macosx", "hunpos-tag")
        when :linux
          return File.join(TextlabOBTStat.root_path,
                           "hunpos", "hunpos-1.0-linux", "hunpos-tag")
        when :windows
          return File.join(TextlabOBTStat.root_path,
                           "hunpos", "hunpos-1.0-win", "hunpos-tag.exe")

        else raise RuntimeError
      end
    end

    ##
    # @private
    def self.hunpos_default_model_fn(format)
      case format
        when 'latin1'
          HUNPOS_LATIN1_MODEL_FN
        when 'utf-8'
          HUNPOS_UTF8_MODEL_FN
        else
          raise NotImplementedError
      end
    end

    # @todo Suppress stderr output from hunpos.
    def run_hunpos(text)
      # info_message(Disambiguator.get_hunpos_command + " " + model_fn)

      hunpos_output = []

      in_file = Tempfile.new('hunpos-in')

      # open in binary to ensure unix line terminators on windows
      File.open(in_file.path, 'wb') do |f|
        text.sentences.each do |s|
          s.words.each do |w|
            # TODO Hunpos should be run on orig string if available.
            # TODO Hunpos should split up combined words
            f.puts w.normalized_string.downcase
          end

          f.puts
        end
      end

      io = IO.popen("#{get_hunpos_command} #{model_fn} < #{in_file.path}", 'r+')

      io.each_line do |line|
        line = line.chomp

        # skip empty lines separating sentences
        unless line == ""
          hun_word, hun_tag = line.split(/\s/)
          hunpos_output.push([hun_word, hun_tag])
        end
      end

      in_file.delete()
      io.close

      hunpos_output
    end

    # This function drives the disambiguation loop over
    # the tokens in the OB annotated input.
    def disambiguate

      # get input
      # @todo get static punctuation switch from params
      @text = OBNOText.parse(@input_file, @sent_seg)

      # run Hunpos
      # info_message "Start running HunPos"
      @hunpos_output = run_hunpos @text
      # info_message "Finished running HunPos"

      # store all data in context
      context = DisambiguationContext.new(@text.words, @hunpos_output)

      @text.sentences.each do |sentence|
        @writer.write_sentence_header(sentence)

        sentence.words.each do
          disambiguate_word(context)
          context.advance
        end

        @writer.write_sentence_footer(sentence)
      end

      @writer.write_postamble(@text)
    end

    def disambiguate_word(context)
      word, hun = context.current

      word_s = word.normalized_string.downcase
      hun_s = hun.first

      if word_s != hun_s
        raise RuntimeError if word.ambigious?

        @writer.write(word)
      else
        word = resolve(word, hun, @lemma_model)

        @writer.write(word)
      end
    end

    # Resolve OBT input ambiguity and mark disambiguated tag as selected.
    #
    # @param [Word] input OBT input word.
    # @param [Array<String>] hunpos Corresponding token tag with Hunpos as token/tag pair.
    # @param [LemmaModel] lemma_model Model to use for lemma disambiguation
    # @return [Word] The Word instance passed as input argument with disambiguated tag marked as selected.
    def resolve(input, hunpos, lemma_model)
      if input.ambigious?
        if input.match_clean_out_tag(hunpos[1])
          # Hunpos tag matches input, only consider matching tags
          candidates = input.tags.find_all { |t| t.equal(hunpos[1]) }
        else
          candidates = input.tags.find_all { |t| t.lemma }
        end

        lemmas = candidates.collect { |t| t.lemma }
        lemma = lemma_model.disambiguate_lemma(input.string, lemmas)

        tags = candidates.find_all { |t| t.lemma.downcase == lemma.downcase }

        # take the first tag with the correct lemma
        tag = tags.first
        # or the first of all OB tags if none with the chosen lemma
        # is available
        tag = input.tags.first if tag.nil?

        tag.selected = true

        input
      else
        raise RuntimeError if input.tags.length > 1

        input.tags.first.selected = true

        input
      end
    end
  end
end
