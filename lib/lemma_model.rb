require_relative 'globals'

module TextlabOBTStat

  class LemmaModel
    # @todo refactor model training to separate class

    UTF8_MODEL_FN = File.join(TextlabOBTStat.root_path,
                              "models", "trening-u-flert-d.lemma_model.utf8")
    LATIN1_MODEL_FN = File.join(TextlabOBTStat.root_path,
                                "models", "trening-u-flert-d.lemma_model")

    UTF8_NOWAC_FREQ_FN = File.join(TextlabOBTStat.root_path,
                                   "models", "nowac07_z10k-lemma-frq-noprop.lst.utf8")
    LATIN1_NOWAC_FREQ_FN = File.join(TextlabOBTStat.root_path,
                                     "models", "nowac07_z10k-lemma-frq-noprop.lst")

    DEFAULT_FILE = "data/trening-u-flert-d.train.cor"
    VERSION_1_FILE_HEADER = "version 1"
    LEMMA_DATA_SEP = "^"

    attr_reader :model, :unknown_model

    def initialize(opts={})
      @lemma_backoff_disambiguation = :nowac # :prefix, :nowac or :nowac_full
      @unknown_model = {}

      @format = opts[:format] || 'utf-8'
      @model_fn = opts[:model_fn] || default_model_fn(@format)
      @model = create_lemma_model(@model_fn)

      if @lemma_backoff_disambiguation == :nowac or @lemma_backoff_disambiguation == :nowac_full
        read_unknown_model
      end
    end

    def default_model_fn(format)
      case format
        when 'utf-8'
          UTF8_MODEL_FN
        when 'latin1'
          LATIN1_MODEL_FN
        else
          raise NotImplementedError
      end
    end

    def nowac_freq_fn(format)
      case format
        when 'utf-8'
          UTF8_NOWAC_FREQ_FN
        when 'latin1'
          LATIN1_NOWAC_FREQ_FN
        else
          NotImplementedError
      end
    end

    def model_entry(word)
      @model[word]
    end


    def top_lemma(word)
      lemmas = @model[word]

      return nil if lemmas.nil?

      top_result = nil

      lemmas.each do |l|
        if top_result.nil?
          top_result = l
        elsif l[1] > top_result[1]
          top_result = l
        end
      end

      top_result[0]
    end

    def prefix_similarity(w1,w2)
      len = [w1.length, w2.length].min

      len.times { |i| return i - 1 if w1[i] != w2[i] }

      len
    end

    def disambiguate_lemma(word, lemma_list)
      word_lookup = @model[word]

      # filter incompatible lemmas
      # TODO handle punctuation with prefixed $
      word_lookup = word_lookup.find_all { |l| lemma_list.include? l.first } if not word_lookup.nil?

      if word_lookup.nil? or word_lookup.empty?
        if @lemma_backoff_disambiguation == :nowac or @lemma_backoff_disambiguation == :nowac_full
          lemma_counts = lemma_list.collect { |lemma| [lemma, @unknown_model[lemma]] }
        elsif @lemma_backoff_disambiguation == :prefix
          lemma_counts = lemma_list.collect { |lemma| [lemma, prefix_similarity(word, lemma)] }
        else
          raise RuntimeError
        end

        if lemma_counts.all? { |x| x[1].nil? }
          return lemma_list.first
        else
          lemma_counts = lemma_counts.find_all { |x| not x[1].nil? }
          return lemma_counts.max { |a,b| a[1] <=> b[1] }.first
        end
      end

      best_score = 0
      best_lemma = nil

      word_lookup.each do |k, v|
        if v > best_score
          best_lemma = k
        end
      end

      raise RuntimeError if best_lemma.nil?

      best_lemma
    end

    def lemma_counts(text)
      lemma_counts = {}
      no_correct = 0

      text.sentences.each do |s|
        s.words.each do |w|
          tag = w.get_correct_tags
          if tag.count != 1
            no_correct += 1
            next
          end

          tag = tag.first
          lemma = tag.lemma

          word = w.string

          data = lemma_counts[word]

          if data.nil?
            lemma_counts[word] = { lemma => 1 }
          elsif data[lemma].nil?
            data[lemma] = 1
          else
            data[lemma] += 1
          end
        end
      end

      [lemma_counts, no_correct]
    end

    # creates a lemma model based on the cor file
    # passed as the file argument, and stores this model
    # in the @model instance variable.
    # file - a proprly formatted cor file. $stdin may be passed
    #        allowing the data to be read from it.
    # returns the populated @model variable
    # @todo probably broken
    def create_lemma_model(file)
      filedata = nil
      @model = {}

      # check if $stdin is passed and read from the fiole or
      # input stream as appropriate
      if file == $stdin
        filedata = $stdin.read
      else
        File.open(file) do |f|
          # parse the cor text data
          text = OBNOText.parse f

          # collect correct lemma counts and construct model
          lc = lemma_counts(text)

          lc.first.each do |k, v|
            word = k
            total = v.values.inject { |sum, n| sum + n }
            lemma_probs = []

            v.each do |k, v|
              lemma_probs << [k, v / total.to_f]
            end

            @model[word] = lemma_probs
          end
        end
      end

      @model
    end

    # Writes the lemma model to a file. The first line in the file is a
    # version header. Subsequent lines contains word forms and lemma/probability
    # pairs sepated by tabs. The lemma strings and probability are separated by
    # a ^ (hat) character.
    # file - the file name to write the model to.
    # returns nil
    def write_lemma_model(file)
      if file == $stdout
        f = $stdout
      else
        f = File.open(file, 'w')
      end

      f.puts VERSION_1_FILE_HEADER

      @model.each do |k, v|
        f.puts k + "\t" + v.collect{ |e| e.join(LEMMA_DATA_SEP)}.join("\t")
      end

      if f != $stdout
        f.close
      end
    end

    # Reads a lemma model from file, and binds it to the @model instance variable.
    # file - name of a file containing a properly formatted model.
    # returns the populated @model instance variable
    def read_lemma_model(file)
      @model = {}
      File.open(file, 'r') do |f|
        # first line should be a valid header
        if f.readline.strip() != VERSION_1_FILE_HEADER
          raise RuntimeError
        end

        f.each_line do |l|
          tokens = l.split("\t")
          word = tokens[0]
          lemmadata = tokens[1...tokens.count]

          lemmas = lemmadata.collect do |e|
            e = e.split(LEMMA_DATA_SEP)
            raise RuntimeError if e.count != 2
            [e[0], e[1].to_f]
          end

          if @model[word]
            raise RuntimeError
          end

          @model[word] = lemmas
        end
      end

      @model
    end

    def read_unknown_model
      File.open nowac_freq_fn(@format) do |f|
        f.each_line do |line|
          vals = line.strip.split
          word = vals[1]
          if @lemma_backoff_disambiguation == :nowac
            freq = vals[3].to_i
          elsif @lemma_backoff_disambiguation == :nowac_full
            freq = vals[0].to_i
          else
            raise RuntimeError
          end

          if @unknown_model[word]
            @unknown_model[word] += freq
          else
            @unknown_model[word] = freq
          end
        end
      end
    end
  end
end
