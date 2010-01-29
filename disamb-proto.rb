#!/local/bin/ruby

require "open3"
require "getoptlong"

require "obno_stubs"
require "obno_text"
require "disambiguator"
require "evaluator"

# $hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag /hf/foni/home/andrely/ob-disambiguation-prototype/disamb.hunpos.model"
$hunpos_command = "./hunpos-1.0-macosx/hunpos-tag"
$hunpos_default_model = "./bm.hunpos.model"

$verbose_output = nil

def counts_to_indices(counts)
  rval = []
  index = 0

  counts.each do |c|
    c.times do |i|
      rval << index 
    end

    index += 1
  end

  return rval
end

def info_message(msg, newline = true)
  $stderr.print msg if $verbose_output
  $stderr.puts if newline
end

def run_disambiguator(inputfile, evalfile)
  evaluator = Evaluator.new(evalfile)

  disambiguator = Disambiguator.new(evaluator)

  disambiguator.input_file = inputfile

  disambiguator.disambiguate
end

if __FILE__ == $0
  eval_file = nil
  input_file = nil

  # parse options
  opts = GetoptLong.new(["--eval", "-e", GetoptLong::REQUIRED_ARGUMENT],
                        ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
                        ["--model", "-m", GetoptLong::REQUIRED_ARGUMENT],
                        ["--verbose", "-v", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--eval":
        eval_file = arg.inspect.delete('"')
    when "--input":
        input_file = arg.inspect.delete('"')
    when "--model":
        $hunpos_default_model = arg.inspect.delete('"')
    when "--verbose":
        $verbose_output = true
    end
  end

  run_disambiguator(input_file, eval_file)
end
