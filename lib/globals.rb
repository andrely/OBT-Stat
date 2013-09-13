module TextlabOBTStat
  def TextlabOBTStat.root_path
    File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  # Remove leading and trailing quotes from string.
  #
  # @param [String] str
  # @return [String]
  def TextlabOBTStat.remove_quotes(str)
    if str.length > 1 and str[0] == '"' and str[-1] == '"'
      str[1...-1]
    else
      str
    end
  end
end
