class LemmaModel
  @@default_file = "data/trening-u-flert-d.train.cor"
  
  def initialize
    text = obno_read(@@default_file)

    @model = create_lemma_model(text)
  end

  def disambiguate_lemma(word, lemma_list)
    word_lookup = @model[word]

    if word_lookup.nil?
      return lemma_list.first
    end
    
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

  def create_lemma_model(text)
    model = {}
    lc = lemma_counts(text)

    lc.first.each do |k, v|
      word = k
      total = v.values.inject { |sum, n| sum + n }
      lemma_probs = []

      v.each do |k, v|
        lemma_probs << [k, v / total.to_f]
      end

      model[word] = lemma_probs
    end

    return model
  end

end
