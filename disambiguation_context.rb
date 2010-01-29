# Data structure for keeping all the disambiguation data, and current indices
# into it
#
# The data:
# input: OB annotated input text, Array of Sentence instances
# hunpos: Hunpos annotated input text, Array of token/tag string pairs
# eval: optional evaluation data, Array of token/tag pairs
#
# The hunpos data contains one item per "word", but the input and eval data
# may contain items that are several collocated words that are treated as one
# token. The _idx variables keeps track of current position for each data array
# to the current position in the input text. This function advances these counters,
# but it is the responsibility of disambiguate_word() to make sure the counters
# account for discrepancies between the data arrays.
class DisambiguationContext
  attr_accessor :input, :hunpos, :eval, :input_idx, :hun_idx, :eval_idx
  
  def initialize
    @input_idx = 0
    @hun_idx = 0
    @eval_idx = 0
  end
  
  # advances all data indices with one, pointing all data arays to the next token
  def advance
    @input_idx += 1
    @hun_idx += 1
    @eval_idx += 1
  end
  
  # returns true if at the end of all data arrays
  def at_end?
    # do we point beyond the end of any of our data arrays ?
    if (@input_idx == @input.length) or (@hun_idx == @hunpos.length) or (@eval_idx == @eval.length)

      # if we're not at the end of all of them we've gone out of sync somewhere
      if not ((@input_idx == @input.length) and (@hun_idx == @hunpos.length) and (@eval_idx == @eval.length))
        raise "End of data out of sync #{@input.length - @input_idx}, #{@hunpos.length - @hun_idx}, #{@eval.length - @eval_idx}"
       else
        return true
      end
    end

    return nil
  end
  
  def at(dataspec, index)
    case dataspec
    when :input
      return @input[index]
    when :eval
      return @eval[index]
    when :hunpos
      return @hunpos[index]
    end

    raise ArgumentError, "Illegal dataspec"
  end

  def pos(dataspec)
    case dataspec
    when :input
      return @input_idx
    when :eval
      return @eval_idx
    when :hunpos
      return @hun_idx
    end

    raise ArgumentError, "Illegal dataspec"
  end

  def current(dataspec, length = nil)
    if length
      pos = pos(dataspec)
      return length.times.collect { |i| at(dataspec, pos + i) }
    else
      case dataspec
      when :input
        return @input[@input_idx]
      when :eval
        return @eval[@eval_idx]
      when :hunpos
        return @hunpos[@hun_idx]
      end

      raise ArgumentError, "Illegal dataspec"

    end
  end
end
