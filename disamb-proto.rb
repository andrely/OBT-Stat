#!/local/bin/ruby

require "open3"
require "getoptlong"

require "obno_stubs"
require "obno_text"
require "disambiguator"
require "evaluator"
require "trace_logger"

# Hunpos command and default model file
# $hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag"
$hunpos_command = "./hunpos-1.0-macosx/hunpos-tag"
# $hunpos_default_model = "./hunpos.model"
$hunpos_default_model = "data/trening-u-flert-d.cor.hunpos_model"
$default_lemma_model = "data/trening-u-flert-d.lemma_model"

# Globally available instanes of the lemma model and trace logger
$tracer = nil
$lemma_model = nil

# set to true for progress info and evaluation output
$verbose_output = nil

# prints messages to $stderr if the verbose switch is set
def info_message(msg, newline = true)
  $stderr.print msg if $verbose_output
  $stderr.puts if newline
end

# sets up the evaluator and disambiguator, then runs the
# disambiguator
def run_disambiguator(inputfile, evalfile)
  evaluator = Evaluator.new(evalfile)

  disambiguator = Disambiguator.new(evaluator)

  disambiguator.input_file = inputfile

  disambiguator.disambiguate
end

if __FILE__ == $0
  eval_file = nil
  input_file = nil
  trace_file = nil

  # parse options
  opts = GetoptLong.new(["--eval", "-e", GetoptLong::REQUIRED_ARGUMENT],
                        ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
                        ["--model", "-m", GetoptLong::REQUIRED_ARGUMENT],
                        ["--lemma-model", "-a", GetoptLong::REQUIRED_ARGUMENT],
                        ["--verbose", "-v", GetoptLong::NO_ARGUMENT],
                        ["--log", "-l", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--eval":
        eval_file = arg.inspect.delete('"')
    when "--input":
        input_file = arg.inspect.delete('"')
    when "--model":
        $hunpos_default_model = arg.inspect.delete('"')
    when "--lemma-model":
        $default_lemma_model = arg.inspect.delete('"')
    when "--verbose":
        $verbose_output = true
    when "--log":
        trace_file = arg.inspect.delete('"')
    end
  end
  
  # set up tracer
  if trace_file
    $tracer = TraceLogger.new(trace_file)
  else
    $tracer = TraceLogger.new(nil, false)
  end
  
  # do the disambiguation
  run_disambiguator(input_file, eval_file)
  
  # stop the tracer
  $tracer.shutdown
end
