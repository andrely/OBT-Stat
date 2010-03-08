#!/opt/local/bin/ruby

# TODO interleaved vs block

# corpus-split train-file held-file eval-file < corpus-file

require 'getoptlong'

require 'obno_stubs'
require 'obno_text'

$input_type = nil

# interleaved
def do_normal_input(train_file, held_file, eval_file)
  empty_regex = Regexp.compile(/^$/)

  index = 0
  fd = nil

  File.open(train_file, 'w') do |tf|
    File.open(held_file, 'w') do |hf|
      File.open(eval_file, 'w') do |ef|
        fd = tf
        
        $stdin.each_line do |line|
          empty = line.match(empty_regex)

          if empty
            fd.puts ""
            
            case index
            when 0..7:
              fd = tf
              index += 1
            when 8:
              fd = hf
              index += 1
            else
              fd = ef
              index = 0
            end
            
          else
            fd.puts line
          end
        end
      end
    end
  end
end

def print_ob_word(word, file=$stdout)
  file.puts "\"<#{word.string}>\""

  word.tags.each do |t|
    file.puts "\t\"#{t.lemma}\"\t#{t.string}#{"\t<Correct!>" if t.correct}"
  end
end

# block
def do_cor_input(train_file, held_file, eval_file)
  text = Text.new

  OBNOText.parse text, $stdin.read
  
  total = text.sentences.count
  train = (total * 0.8).floor
  held = (total * 0.1).floor
  eval = total - train - held

  File.open(train_file, 'w') do |f|
    text.sentences[0...train].each do |s|
      s.words.each do |w|
        print_ob_word(w, f)
      end
    end

    f.puts
  end

  File.open(held_file, 'w') do |f|
    text.sentences[train...(train + held)].each do |s|
      s.words.each do |w|
        print_ob_word(w, f)
      end
    end

    f.puts
  end

  File.open(eval_file, 'w') do |f|
    text.sentences[(train + held)...(train + held + eval)].each do |s|
      s.words.each do |w|
        print_ob_word(w, f)
      end
    end

    f.puts
  end
end

if __FILE__ == $0
  opts = GetoptLong.new(["--type", "-t", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--type":
        if arg == "cor"
          $input_type = :cor
        else
          raise RuntimeError
        end
    end
  end

  train_file = ARGV[0]
  held_file = ARGV[1]
  eval_file = ARGV[2]
  
  if $input_type == :cor
    do_cor_input(train_file, held_file, eval_file)
  else
    do_normal_input(train_file, held_file, eval_file)
  end
end
