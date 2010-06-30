$empty_regex = Regexp.compile(/^$/)

if __FILE__ == $0
  train_path, train_file = File.split ARGV[0]
  eval_path, eval_file = File.split ARGV[1]
  
  fold = 0
  
  10.times.each do |i|
    begin
      Dir.mkdir "#{train_path}/#{i}"
      Dir.mkdir "#{train_path}/#{i}"
    rescue Errno::EEXIST
    end
  end
  
  fold_fd_a = 10.times.each.collect { |i| [File.open("#{train_path}/#{i}/#{train_file}", 'w'),
                                           File.open("#{eval_path}/#{i}/#{eval_file}", 'w')] }
  
  lines = $stdin.readlines

  boundary = false
  sentence_count = 1
  
  lines.each do |line|
    line.strip!
    empty = line.match($empty_regex)
    
    if not boundary and empty
      boundary = true
      sentence_count += 1
    elsif boundary and empty
      # nothing
    else
      boundary = false
    end
  end

  fold_size = sentence_count / 10 # round down
  count = 0

  lines.each do |line|
    line.strip!
    empty = line.match($empty_regex)

    10.times.each do |i|
      if i == fold
        fold_fd_a[i][1].puts line
      else
        fold_fd_a[i][0].puts line
      end
    end

    if empty
      count += 1

      if (count >= fold_size) and fold < 9
        fold += 1
        count = 0
      end
    end
  end

  fold_fd_a.each { |fds| fds[0].close; fds[1].close }
end
