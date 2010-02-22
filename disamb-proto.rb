#!/local/bin/ruby

require "open3"
require "getoptlong"

require "obno_stubs"
require "obno_text"
require "disambiguator"
require "evaluator"
require "lemma_model"

$eval_file = nil
$log_file = "log"
$log_fd = nil
# $hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag /hf/foni/home/andrely/ob-disambiguation-prototype/disamb.hunpos.model"
$hunpos_command = "./hunpos-1.0-macosx/hunpos-tag"
$hunpos_default_model = "./bm.hunpos.model"

$lemma_model = nil

$verbose_output = nil

def obno_read(file)
  text = Text.new

  OBNOText.parse text, File.open(file).read

  return text
end

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
                        ["--verbose", "-v", GetoptLong::NO_ARGUMENT],
                        ["--log", "-l", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--eval":
        $eval_file = arg.inspect.delete('"')
    when "--input":
        input_file = arg.inspect.delete('"')
    when "--model":
        $hunpos_default_model = arg.inspect.delete('"')
    when "--verbose":
        $verbose_output = true
    when "--log":
        $log_file = arg.inspect.delete('"')
    end
  end

  $log_fd = File.open($log_file, 'w')

  run_disambiguator(input_file, $eval_file)

  $log_fd.close
end
