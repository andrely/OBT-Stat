# Data structure for keeping all the disambiguation data, and current indices
# into it
#
# This class might be obsolete since we no longer synchronize to a separate
# evaluation file
#
# The data:
# input: OB annotated input text, Array of Sentence instances
# hunpos: Hunpos annotated input text, Array of token/tag string pairs
#
# The hunpos data contains one item per "word", but the input
# may contain items that are several collocated words that are treated as one
# token. The _idx variables keeps track of current position for each data array
# to the current position in the input text. This function advances these counters,
# but it is the responsibility of disambiguate_word() to make sure the counters
# account for discrepancies between the data arrays.
class DisambiguationContext
  attr_accessor :input, :hunpos, :input_idx, :hun_idx
  
  def initialize
    @input_idx = 0
    @hun_idx = 0
  end
  
  # advances both data indices with one, pointing both data arays to the next token
  def advance
    @input_idx += 1
    @hun_idx += 1
  end
  
  # returns true if at the end of both data arrays
  def at_end?
    # do we point beyond the end of any of our data arrays ?
    if (@input_idx == @input.length) or (@hun_idx == @hunpos.length)

      # if we're not at the end of both of them we've gone out of sync somewhere
      if not ((@input_idx == @input.length) and (@hun_idx == @hunpos.length))
        raise "End of data out of sync #{@input.length - @input_idx}, #{@hunpos.length - @hun_idx}"
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
    when :hunpos
      return @hunpos[index]
    end

    raise ArgumentError, "Illegal dataspec"
  end

  def pos(dataspec)
    case dataspec
    when :input
      return @input_idx
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
      when :hunpos
        return @hunpos[@hun_idx]
      end

      raise ArgumentError, "Illegal dataspec"
    end
  end

  def synchronize
    input_s = current(:input).normalized_string.downcase

    input_len = Disambiguator.token_word_count(input_s)

    if input_len > 1
      # hunpus is identical to input
      return [current(:input)]
    else
      # some tokens will be connected with the next token in eval or input
      # eg. Tir/Tir.
      return [current(:input)]
    end
  end
end
