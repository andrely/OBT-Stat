#!/usr/bin/env ruby

# Converts vertical format into sentences.

if __FILE__ == $0
  sent = []
  $stdin.each_line do |line|
    line.strip!
    
    if line == ""
      puts sent.join ' '
      sent = []
    else
      sent << line
    end
  end

  puts sent.join ' ' if sent != []
end
