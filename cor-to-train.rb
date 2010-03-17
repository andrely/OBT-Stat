#!/opt/local/bin/ruby

require 'obno_stubs'
require 'obno_text'

if __FILE__ == $0
  cor_file = ARGV[0]
  
  File.open(cor_file) do |f|
    text = OBNOText.parse f

    text.sentences.each do |s|
      s.words.each do |w|
        raise RuntimeError if w.correct_count > 1

        if w.correct_count == 0
          puts "#{w.normalized_string}\tukjent\tukjent"
        else
          # careful, throw error on words with multiple correct tags
          raise RuntimeError if w.correct_count > 1
          
          tag = w.get_correct_tags.first
          puts "#{w.normalized_string}\t#{tag.clean_out_tag}\t#{tag.lemma}"
        end
      end

      puts
    end
  end  
end
