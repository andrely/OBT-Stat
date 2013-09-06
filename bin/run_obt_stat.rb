#!/usr/bin/env ruby

require "open3"
require "getoptlong"
require "rbconfig"

require_relative '../lib/writers'
require_relative '../lib/disambiguator'

# prints messages to $stderr if the verbose switch is set
def info_message(msg, newline = true)
  $stderr.print msg if $verbose_output
  $stderr.puts if newline
end

def print_help
  puts "Help!"
end

# sets up the evaluator and disambiguator, then runs the
# disambiguator
def run_disambiguator(params)
  params[:input_file] = File.open(params[:input_fn], 'r') if params[:input_fn]

  disambiguator = Disambiguator.new(params)

  disambiguator.disambiguate

  params[:input_file].close if params[:input_file]
end

if true #  __FILE__ == $0
  params = { writer: InputWriter.new,
             format: "utf-8" }

  # parse options
  opts = GetoptLong.new(["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
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
    when "--input"
        params[:input_fn] = arg.inspect.delete('"')
    when "--model"
        params[:hunpos_model_fn] = arg.inspect.delete('"')
    when "--lemma-model"
        params[:lemma_model_fn] = arg.inspect.delete('"')
    when "--verbose"
        params[:verbose] = true
    when "--log"
        if arg == ""
          # setup trace to stderr
        else
          params[:log_file] = arg.inspect.delete('"')
        end
    when "--output"
        if arg == "echo"
          # default writer
        elsif arg == "vrt"
          params[:writer] = VRTWriter.new
        elsif arg == "mark"
          params[:writer] = MarkWriter.new
        else
          print_help
          exit
        end
    when "--format"
        if arg == "utf8" or arg == "utf-8"
          # default format
        elsif arg == "latin1" or arg == "latin-1" or arg == "iso-8859-1"
          params[:format] = 'latin-1'
        else
          print_help
          exit
        end
    when "--static-punctuation"
      params[:static_punctuation] = true
    when "--help"
        print_help
        exit
    end
  end

  # do the disambiguation
  run_disambiguator(params)
end
