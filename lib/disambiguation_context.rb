module TextlabOBTStat

  ##
  # Class for keeping the parallel OBT and Hunpos data
  #
  # @todo This class might be folded into Disambiguator or DisambiguationUnit.
  class DisambiguationContext

    attr_reader :input, :hunpos, :idx

    # @param [Array] obt_input Array of OBNO Sentence instances.
    # @param [Array] hunpos_input Array of Array instances with word/tag pairs.
    # @raise [ArgumentError] If Hunpos and OBT data have inconsistent token count.
    def initialize(obt_input, hunpos_input)
      @idx = 0

      @input = obt_input
      @hunpos = hunpos_input

      unless @input.count == @hunpos.count
        raise(ArgumentError, "Inconsistent token count in OBT and Hunpos data.")
      end
    end

    # advances both data indices with one, pointing both data arrays to the next token
    def advance
      @idx += 1
    end

    # returns true if at the end of both data arrays
    # @return [TrueClass, FalseClass]
    def at_end?
      #noinspection RubyResolve
      (@idx >= @input.length) or (@idx >= @hunpos.length)
    end

    # @return [[Word, Array]] The OBT word and Hunpos token/tag pair at the current index
    def current
      return @input[@idx], @hunpos[@idx]
    end
  end
end
