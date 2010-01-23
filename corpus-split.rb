#!/opt/local/bin/ruby

# corpus-split train-file held-file eval-file < corpus-file

if __FILE__ == $0
  train_file = ARGV[0]
  held_file = ARGV[1]
  eval_file = ARGV[2]

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
