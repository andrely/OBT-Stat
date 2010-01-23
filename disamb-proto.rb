#!/local/bin/ruby

require "open3"
require "getoptlong"

require "obno_stubs"
require "obno_text"
require "disambiguator"
require "evaluator"

# $hunpos_command = "/hf/foni/home/andrely/ob-disambiguation-prototype/hunpos-1.0-linux/hunpos-tag /hf/foni/home/andrely/ob-disambiguation-prototype/disamb.hunpos.model"
$hunpos_command = "./hunpos-1.0-macosx/hunpos-tag ./bm.hunpos.model"

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
                        ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--eval":
        eval_file = arg.inspect.delete('"')
    when "--input":
        input_file = arg.inspect.delete('"')
    end
  end

  run_disambiguator(input_file, eval_file)
end
