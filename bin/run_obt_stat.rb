#!/usr/bin/env ruby

require "open3"
require "getoptlong"
require "rbconfig"
require 'logger'

require_relative '../lib/writers'
require_relative '../lib/disambiguator'

# TODO setup this properly
$logger = Logger.new($stderr)

module TextlabOBTStat

  def TextlabOBTStat.print_help
    puts "Help!"
  end

# sets up the evaluator and disambiguator, then runs the
# disambiguator
  def TextlabOBTStat.run_disambiguator(params)
    params[:input_file] = File.open(params[:input_fn], 'r') if params[:input_fn]
    # instantiate writer with params based on command line arguments
    params[:writer] = params[:writer].new(:xml => params[:sent_seg] == :xml)

    disambiguator = TextlabOBTStat::Disambiguator.new(params)

    disambiguator.disambiguate

    params[:input_file].close if params[:input_file]
  end

end

if __FILE__ == $0
  # default argument values
  params = { :writer => TextlabOBTStat::InputWriter,
             :sent_seg => :mtag,
             :format => "utf-8" }

  # parse options
  opts = GetoptLong.new(["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
                        ["--model", "-m", GetoptLong::REQUIRED_ARGUMENT],
                        ["--lemma-model", "-a", GetoptLong::REQUIRED_ARGUMENT],
                        ["--verbose", "-v", GetoptLong::NO_ARGUMENT],
                        ["--log", "-l", GetoptLong::OPTIONAL_ARGUMENT],
                        ["--output", "-o", GetoptLong::REQUIRED_ARGUMENT],
                        ["--format", "-f", GetoptLong::REQUIRED_ARGUMENT],
                        ["--help", "-h", GetoptLong::NO_ARGUMENT],
                        ["--sent-seg", "-s", GetoptLong::REQUIRED_ARGUMENT])

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
          params[:writer] = TextlabOBTStat::VRTWriter
        elsif arg == "mark"
          params[:writer] = TextlabOBTStat::MarkWriter
        else
          TextlabOBTStat.print_help
          exit
        end
      when "--format"
        if arg == "utf8" or arg == "utf-8"
          # default format
        elsif arg == "latin1" or arg == "latin-1" or arg == "iso-8859-1"
          params[:format] = 'latin-1'
        else
          TextlabOBTStat.print_help
          exit
        end
      when "--sent-seg"
        arg = arg.strip.to_sym

        unless [:static, :mtag, :xml].member?(arg)
          TextlabOBTStat.print_help
          exit
        end

        params[:sent_seg] = arg
      when "--help"
        TextlabOBTStat.print_help
        exit
      else
        $logger.warn("Invalid option #{opt}")
    end
  end

  # do the disambiguation
  TextlabOBTStat.run_disambiguator(params)
end
