class Evaluator
  attr_reader :evaluation_file

  def initialize
    @evaluation_file = nil
    @active = nil
  end

  def evaluation_file=(filename)
    @evaluation_file = filename
    @active = true
  end
end