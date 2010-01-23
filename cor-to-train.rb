#!/opt/local/bin/ruby

require 'obno_stubs'
require 'obno_text'

if __FILE__ == $0
  cor_file = ARGV[0]

  text = Text.new
  OBNOText.parse text, File.open(cor_file).read

  text.sentences.each do |s|
    s.words.each do |w|
      raise RuntimeError if w.correct_count > 1

      if w.correct_count == 0
        puts "#{w.normalized_string}\tukjent"
      else
        puts "#{w.normalized_string}\t#{w.get_correct_tags.first.clean_out_tag}"
      end
    end

    puts
  end
end
