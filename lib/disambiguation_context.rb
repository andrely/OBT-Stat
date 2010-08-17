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
  attr_accessor :input, :hunpos, :eval, :input_idx, :hun_idx, :eval_idx, :eval_active
  
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
    if (@input_idx == @input.length) or (@hun_idx == @hunpos.length) or (@eval_active and (@eval_idx == @eval.length))

      # if we're not at the end of all of them we've gone out of sync somewhere
      if eval_active
        if not ((@input_idx == @input.length) and (@hun_idx == @hunpos.length) and (@eval_idx == @eval.length))
          raise "End of data out of sync #{@input.length - @input_idx}, #{@hunpos.length - @hun_idx}, #{@eval.length - @eval_idx}"
        else
          return true
        end
      else
        if not ((@input_idx == @input.length) and (@hun_idx == @hunpos.length))
          raise "End of data out of sync #{@input.length - @input_idx}, #{@hunpos.length - @hun_idx}"
        else
          return true
        end

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
        if @eval_active
          return @eval[@eval_idx]
        else
          return nil
        end
      when :hunpos
        return @hunpos[@hun_idx]
      end

      raise ArgumentError, "Illegal dataspec"
    end
  end

  def synchronize
    input_s = current(:input).normalized_string.downcase
    eval_s = current(:eval).first.downcase

    input_len = Disambiguator.token_word_count(input_s)
    eval_len = Disambiguator.token_word_count(eval_s)
    
    if input_s == eval_s
      # This case is checked for in Disambiguator.disambiguate_word but is done again
      # here to avoid throwing errors when a joined word is present both in input and eval.
      return [current(:input)]
    elsif input_len > 1 and eval_len > 1
      # not possible, if both input and eval are joined they should be equal
      # and caught above
      raise RuntimeError
    elsif input_len > 1
      joined_eval = @eval[@eval_idx...(@eval_idx + input_len)].collect { |e| e.first }.join('_')
      
      # normalizing before comparing
      # TODO centralize normalizing
      if not (input_s.downcase == joined_eval.downcase)
        raise RuntimeError
      else
        @eval_idx += input_len - 1
        # hunpus is identical to input
        return [current(:input)]
      end
    elsif eval_len > 1
      joined_input = @input[@input_idx...(@input_idx + eval_len)].collect { |e| e.normalized_string}.join('_')

      # TODO centralize normalizing of input
      if not (eval_s.downcase == joined_input.downcase)
        raise RuntimeError
      else
        input = @input[@input_idx...(@input_idx + eval_len)]
        @input_idx += eval_len -1
        @hun_idx += eval_len - 1

        return input
      end
    else
      # some tokens will be connected with the next token in eval or input
      # eg. Tir/Tir.

      # TODO guard against array end here
      input_next = input_s + @input[@input_idx + 1].normalized_string
      eval_next = eval_s + @eval[@eval_idx + 1].first

      if input_next.downcase == eval_s.downcase
        input = @input[@input_idx...(@input_idx + 2)]
        @input_idx += 1
        @hun_idx += 1

        return input

      # TODO centralize normalization
      elsif eval_next.downcase == input_s.downcase
        if @input[@input_idx + 1].normalized_string !=  @eval[@eval_idx + 1][0]
          @eval_idx += 1
        end

        return [current(:input)]

      else
        raise RuntimeError
      end
    end
  end
end
