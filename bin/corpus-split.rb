#!/usr/bin/env ruby

# Script to split corpus into CV blocks

# TODO interleaved vs block

# corpus-split train-file held-file eval-file < corpus-file

require 'getoptlong'
require 'logger'

require '../lib/obno_stubs'
require '../lib/obno_text'

$input_type = nil
$split_type = :interleave

$logger = Logger.new($stderr)
# interleaved
def do_normal_input(train_file, held_file, eval_file)
  empty_regex = Regexp.compile(/^$/)

  index = 0

  File.open(train_file, 'w') do |tf|
    File.open(held_file, 'w') do |hf|
      File.open(eval_file, 'w') do |ef|
        fd = tf
        
        $stdin.each_line do |line|
          empty = line.match(empty_regex)

          if empty
            fd.puts ""
            
            case index
            when 0..7
              fd = tf
              index += 1
            when 8
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
def do_cor_input_block(train_file, held_file, eval_file)
  text = OBNOText.parse $stdin
  
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

def do_cor_input_interleave(train_file, held_file, eval_file)
  text = OBNOText.parse $stdin

  index = 0

  File.open(train_file, 'w') do |tf|
    File.open(held_file, 'w') do |hf|
      File.open(eval_file, 'w') do |ef|
        text.sentences.each do |s|
          case index
            when 0..7
              fd = tf
              index += 1
            when 8
              fd = hf
              index += 1
            else
              fd = ef
              index = 0
          end

          s.words.each do |w|
            print_ob_word(w, fd)
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  opts = GetoptLong.new(["--type", "-t", GetoptLong::REQUIRED_ARGUMENT],
                        ["--interleave", "-i", GetoptLong::NO_ARGUMENT],
                        ["--block", "-b", GetoptLong::NO_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--type"
        if arg == "cor"
          $input_type = :cor
        else
          raise RuntimeError
        end
    when "--interleave"
        $split_type = :interleave
    when "--block"
        $split_type = :block
    else
        logger.warn("Invalid option #{opt}")
    end
  end

  train_file = ARGV[0]
  held_file = ARGV[1]
  eval_file = ARGV[2]

  if $input_type.nil? and $split_type == :block
    raise RuntimeError
  end
  
  if $input_type == :cor
    if $split_type == :interleave
      do_cor_input_interleave(train_file, held_file, eval_file)
    else
      do_cor_input_block(train_file, held_file, eval_file)
    end
    
  else
    do_normal_input(train_file, held_file, eval_file)
  end
end
