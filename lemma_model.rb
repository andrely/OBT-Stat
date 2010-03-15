require 'evaluator'

class LemmaModel
  @@default_file = "data/trening-u-flert-d.train.cor"
  @@version_1_file_header = "version 1"
  @@lemma_data_sep = "^"

  attr_reader :model
  
  def initialize(evaluator = nil, file = @@default_file)
    @model = {}

    @evaluator = evaluator
  end
  
  def model_entry(word)
    return @model[word]
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

    return top_result[0]
  end

  def disambiguate_lemma(word, lemma_list)
    word_lookup = @model[word]

    if word_lookup.nil?
      @evaluator.mark_lemma_miss
      
      return lemma_list.first
    end

    @evaluator.mark_lemma_hit
    
    best_score = 0
    best_lemma = nil
    
    word_lookup.each do |k, v|
      if v > best_score
        best_lemma = k
      end
    end

    raise RuntimeError if best_lemma.nil?
    
    return best_lemma
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

    return [lemma_counts, no_correct]
  end
  
  # creates a lemma model based on the cor file
  # passed as the file argument, and stores this model
  # in the @model instance variable.
  # file - a proprly formatted cor file. $stdin may be passed
  #        allowing the data to be read from it.
  # returns the populated @model variable
  def create_lemma_model(file)
    filedata = nil
    @model = {}

    # check if $stdin is passed and read from the fiole or
    # input stream as appropriate
    if file == $stdin
      filedata = $stdin.read
    else
      File.open(file) do |f|
        filedata = f.read
      end
    end
    
    # parse the cor text data
    text = Text.new
    OBNOText.parse text, filedata
    
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

    return @model
  end
  
  # Writes the lemma model to a file. The first line in the file is a
  # version header. Subsequent lines contains word forms and lemma/probability
  # pairs sepated by tabs. The lemma strings and probability are separated by
  # a ^ (hat) character.
  # file - the file name to write the model to.
  # returns nil
  def write_lemma_model(file)
    f = nil
    
    if file == $stdout
      f = $stdout
    else
      f = File.open(file, 'w')
    end
    
    f.puts @@version_1_file_header
    
    @model.each do |k, v|
      f.puts k + "\t" + v.collect{ |e| e.join(@@lemma_data_sep)}.join("\t")
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
      if f.readline.strip() != @@version_1_file_header
        raise RuntimeError
      end

      f.each_line do |l|
        tokens = l.split("\t")
        word = tokens[0]
        lemmadata = tokens[1...tokens.count]

        lemmas = lemmadata.collect do |e|
          e = e.split(@@lemma_data_sep)
          raise RuntimeError if e.count != 2
          [e[0], e[1].to_f]
        end

        if @model[word]
          raise RuntimeError
        end
        
        @model[word] = lemmas
      end
    end

    return @model
  end
end
