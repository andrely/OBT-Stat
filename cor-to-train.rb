#!/opt/local/bin/ruby

require 'obno_stubs'
require 'obno_text'

def get_word_string(word)
  if word.capitalized?
    return word.normalized_string.capitalize
  else
    return word.normalized_string
  end
end

if __FILE__ == $0
  cor_file = ARGV[0]
  
  File.open(cor_file) do |f|
    text = OBNOText.parse f

    text.sentences.each do |s|
      s.words.each do |w|
        raise RuntimeError if w.correct_count > 1

        if w.correct_count == 0
          puts "#{get_word_string(w)}\tukjent\tukjent"
        else
          # careful, throw error on words with multiple correct tags
          raise RuntimeError if w.correct_count > 1
          
          tag = w.get_correct_tags.first
          puts "#{get_word_string(w)}\t#{tag.clean_out_tag}\t#{tag.lemma}"
        end
      end

      puts
    end
  end  
end
