require 'rbconfig'
require 'tempfile'

require_relative 'disambiguation_context'
require_relative 'obno_stubs'
require_relative 'obno_text'
require_relative 'lemma_model'
require_relative 'writers'
require_relative 'obt_stat'
require_relative 'disambiguation_unit'

module TextlabOBTStat

  # @todo Should disambiguate on original word if present, such that capitalized first words
  #   in a sentence is used. Currently hunpos is passed normailized string.
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
      @writer = opts[:writer] || InputWriter.new
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

    def run_hunpos(text)
      # info_message(Disambiguator.get_hunpos_command + " " + model_fn)

      hunpos_output = []

      in_file = Tempfile.new('hunpos-in')

      # open in binary to ensure unix line terminators on windows
      File.open(in_file.path, 'wb') do |f|
        text.sentences.each do |s|
          s.words.each do |w|
            # TODO Hunpos should be run on orig string if available.
            f.puts w.normalized_string.downcase
          end

          f.puts
        end
      end

      io = IO.popen("#{get_hunpos_command} #{model_fn} < #{in_file.path}", 'r+')

      io.each_line do |line|
        line = line.chomp

        # skip empty lines separating sentences
        if not line == ""
          hun_word, hun_tag = line.split(/\s/)
          hunpos_output.push([hun_word, hun_tag])
        end
      end

      in_file.delete()
      io.close

      return hunpos_output
    end

    # This function drives the disambiguation loop over
    # the tokens in the OB annotated input.
    def disambiguate

      # get input
      # @todo get static punctuation switch from params
      @text = OBNOText.parse(@input_file, true)

      # run Hunpos
      # info_message "Start running HunPos"
      @hunpos_output = run_hunpos @text
      # info_message "Finished running HunPos"

      # store all data in context
      context = DisambiguationContext.new(@text.words, @hunpos_output)

      until context.at_end?
        disambiguate_word(context)
        context.advance
      end

      @writer.write_postamble(@text)
    end

    def disambiguate_word(context)
      word, hun = context.current

      word_s = word.normalized_string.downcase
      hun_s = hun.first

      unless word_s == hun_s
        raise RuntimeError if word.ambigious?

        @writer.write(word)
      else
        unit = DisambiguationUnit.new(word, hun, @lemma_model)
        word = unit.resolve

        @writer.write(word)

      end

      if word.end_of_sentence?
        @writer.write_sentence_delimiter(word)
      end
    end

    def self.token_word_count(token)
      return token.split('_').count
    end
  end
end
