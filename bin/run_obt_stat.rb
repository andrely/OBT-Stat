#!/usr/bin/env ruby

require "open3"
require "getoptlong"
require "rbconfig"

$path = File.expand_path(File.dirname(__FILE__))

# if we cannot require this file we're running locally and outside
# the application directory. Try again with the absolute path
begin
  require "obt_stat"
rescue LoadError
  if File.split($path).last != "bin"
    # called from root symlink
    $path = $path + "/bin"
  end

  require $path + "/obt_stat"
end

# Globally available instanes of the lemma model, writer and trace logger
$tracer = nil
$lemma_model = nil
$writer = InputWriter.new

# set to true for progress info and evaluation output
$verbose_output = nil

$eval_output = nil

$static_punctuation = nil

# prints messages to $stderr if the verbose switch is set
def info_message(msg, newline = true)
  $stderr.print msg if $verbose_output
  $stderr.puts if newline
end

def print_help
  puts "Help!"
end

def detect_platform
  if Config::CONFIG['host_os'] =~ /mswin|mingw|win32|cygwin/
    return :windows
  end

  if Config::CONFIG['host_os'] =~ /darwin/
    return :osx
  end

  if Config::CONFIG['host_os'] =~ /linux/
    return :linux
  end

  return :unknown
end

def get_hunpos_command
  case detect_platform
  when :osx
    return $path + "/../hunpos/hunpos-1.0-macosx/hunpos-tag"
  when :linux
    return $path + "/../hunpos/hunpos-1.0-linux/hunpos-tag"
  when :windows
    return $path + "/../hunpos/hunpos-1.0-win/hunpos-tag.exe"
  
  else raise RuntimeError
  end
end

# sets up the evaluator and disambiguator, then runs the
# disambiguator
def run_disambiguator(inputfile)
  evaluator = Evaluator.new $eval_output

  disambiguator = Disambiguator.new(evaluator)

  disambiguator.input_file = inputfile

  disambiguator.disambiguate
end

$hunpos_command = get_hunpos_command
$hunpos_default_model = $path + "/../models/trening-u-flert-d.cor.hunpos_model.utf8"
$default_lemma_model = $path + "/../models/trening-u-flert-d.lemma_model.utf8"
$nowac_freq_file = $path + "/../models/nowac07_z10k-lemma-frq-noprop.lst.utf8"

if true #  __FILE__ == $0
  input_file = nil
  trace_file = nil

  # parse options
  opts = GetoptLong.new(["--eval", "-e", GetoptLong::NO_ARGUMENT],
                        ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
                        ["--model", "-m", GetoptLong::REQUIRED_ARGUMENT],
                        ["--lemma-model", "-a", GetoptLong::REQUIRED_ARGUMENT],
                        ["--verbose", "-v", GetoptLong::NO_ARGUMENT],
                        ["--log", "-l", GetoptLong::OPTIONAL_ARGUMENT],
                        ["--output", "-o", GetoptLong::REQUIRED_ARGUMENT],
                        ["--format", "-f", GetoptLong::REQUIRED_ARGUMENT],
                        ["--help", "-h", GetoptLong::NO_ARGUMENT],
                        ["--static-punctuation", "-s", GetoptLong::NO_ARGUMENT])

  opts.each do |opt, arg|
    case opt
    when "--eval"
        $eval_output = true
    when "--input"
        input_file = arg.inspect.delete('"')
    when "--model"
        $hunpos_default_model = arg.inspect.delete('"')
    when "--lemma-model"
        $default_lemma_model = arg.inspect.delete('"')
    when "--verbose"
        $verbose_output = true
    when "--log"
        if arg == ""
          # setup trace to stderr
        else
          trace_file = arg.inspect.delete('"')
        end
    when "--output"
        if arg == "echo"
          # default writer
        elsif arg == "vrt"
          $writer = VRTWriter.new
        elsif arg == "mark"
          $writer = MarkWriter.new
        else
          print_help
          exit
        end
    when "--format"
        if arg == "utf8" or arg == "utf-8"
          # default format
        elsif arg == "latin1" or arg == "latin-1" or arg == "iso-8859-1"
          $hunpos_default_model = $path + "/../models/trening-u-flert-d.cor.hunpos_model"
          $default_lemma_model = $path + "/../models/trening-u-flert-d.lemma_model"
          $nowac_freq_file = $path + "/../models/nowac07_z10k-lemma-frq-noprop.lst"
        else
          print_help
          exit
        end
    when "--static-punctuation"
      $static_punctuation = true
    when "--help"
        print_help
        exit
    end
  end
  
  # set up tracer
  if trace_file
    $tracer = TraceLogger.new(trace_file)
  else
    $tracer = TraceLogger.new(nil, false)
  end
  
  # do the disambiguation
  run_disambiguator(input_file)
  
  # stop the tracer
  $tracer.shutdown
end
